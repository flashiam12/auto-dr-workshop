locals {
  vpc_cidr = "10.0.0.0/18"
  private_subnets = cidrsubnets(cidrsubnets(local.vpc_cidr,2,2)[0],2,2)
  public_subnets = cidrsubnets(cidrsubnets(local.vpc_cidr,2,2)[1],2,2)
}
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name = "centene-workshop"
  cidr = local.vpc_cidr
  azs             = ["us-east-2a", "us-east-2b"]
  private_subnets = local.private_subnets
  public_subnets  = local.public_subnets
  map_public_ip_on_launch = true
  enable_nat_gateway = false
  create_egress_only_igw = true
  flow_log_file_format = "plain-text"

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.eks_cluster_name}" = "owned"
    "kubernetes.io/role/elb" = 1
    "kubernetes.io/role/internal-elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.eks_cluster_name}" = "owned"
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = {
    Terraform = "true"
    Environment = "dev"
    Owner = "Shiv"
    Team = "STS"
  }
}

data "http" "myip" {
  url = "https://ipv4.icanhazip.com"
}

resource "aws_security_group_rule" "https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks = ["${chomp(data.http.myip.response_body)}/32"]
  security_group_id = module.vpc.default_security_group_id
}

resource "aws_security_group_rule" "kafka" {
  type              = "ingress"
  from_port         = 9092
  to_port           = 9092
  protocol          = "tcp"
  cidr_blocks = ["${chomp(data.http.myip.response_body)}/32"]
  security_group_id = module.vpc.default_security_group_id
}

resource "aws_security_group_rule" "ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks = ["${chomp(data.http.myip.response_body)}/32"]
  security_group_id = module.vpc.default_security_group_id
}

resource "aws_security_group_rule" "allow_all" {
  type              = "egress"
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  security_group_id = module.vpc.default_security_group_id
}

resource "aws_route" "cc_primary_network" {
  for_each = toset(module.vpc.public_route_table_ids)
  route_table_id = each.key
  destination_cidr_block = confluent_network.primay-network-transit-gateway.cidr
  transit_gateway_id = module.tgw.ec2_transit_gateway_id
}

resource "aws_route" "cc_secondary_network" {
  for_each = toset(module.vpc.public_route_table_ids)
  route_table_id = each.key
  destination_cidr_block = confluent_network.secondary-network-transit-gateway.cidr
  transit_gateway_id = module.tgw.ec2_transit_gateway_id
}

module "tgw" {
  source  = "terraform-aws-modules/transit-gateway/aws"
  version = "~> 2.0"
  name        = "centene-workshop-cc-tgw"
  description = "TGW for centene workshop"
  enable_auto_accept_shared_attachments = true
  vpc_attachments = {
    vpc = {
      vpc_id       = module.vpc.vpc_id
      subnet_ids   = module.vpc.private_subnets
      dns_support  = true
      ipv6_support = false
      tgw_routes = [
        {
          destination_cidr_block = local.vpc_cidr
        }
      ]
    }
  }

  ram_allow_external_principals = true
  ram_principals = [confluent_network.primay-network-transit-gateway.aws[0].account, confluent_network.secondary-network-transit-gateway.aws[0].account]

  tags = {
    Terraform = "true"
    Environment = "dev"
    Owner = "Shiv"
    Team = "STS"
  }
}

resource "tls_private_key" "bastion" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "bastion" {
  key_name   = "centene-bastion"
  public_key = tls_private_key.bastion.public_key_openssh

  tags = {
    Name = "centene-bastion"
    Purpose = "bastion-host"
  }
}

resource "local_file" "private_key_pem_bastion" {
  content = tls_private_key.bastion.private_key_pem
  filename            = "${path.module}/secrets/${aws_key_pair.bastion.key_name}_private_key.pem"
  file_permission    = "0600"
}

resource "local_file" "public_key_bastion" {
  content = tls_private_key.bastion.public_key_openssh
  filename           = "${path.module}/secrets/${aws_key_pair.bastion.key_name}_public_key.pub"
  file_permission   = "0644"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  name = "centene-workshop-bastion"
  ami = data.aws_ami.ubuntu.id
  instance_type          = "t3.large"
  key_name               = aws_key_pair.bastion.key_name
  monitoring             = true
  vpc_security_group_ids = [module.vpc.default_security_group_id]
  subnet_id              = module.vpc.public_subnets[0]
  tags = {
    Terraform   = "true"
    Environment = "dev"
    Owner = "Shiv"
    Team = "STS"
    "aws_cleaner/stop/date" = "2024-09-02"
  }
}


##################################### AWS CLUSTER AUTH #########################################
locals {
  eks_cluster_name = "centene-ha-workshop"
}

# data "aws_eks_cluster_auth" "cluster" {
#   name = module.eks.cluster_name
# }
# data "aws_eks_cluster" "cluster" {
#   name = module.eks.cluster_name
# }

##################################### AWS CLUSTER NODE POOL IAM ROLE BINDING #########################################

resource "aws_iam_role" "node" {
  name = "${local.eks_cluster_name}-node-group"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node.name
}

resource "aws_iam_policy" "worker_policy" {
  name        = "${local.eks_cluster_name}-worker-policy"
  description = "Worker policy for the ALB Ingress"
  policy = file("${path.module}/configs/worker-policy.json")
}

resource "aws_iam_role_policy_attachment" "ALBIngressEKSPolicyCustom" {
  policy_arn = aws_iam_policy.worker_policy.arn
  role       = aws_iam_role.node.name
}

##################################### AWS CLUSTER AUTH CONFIG MAP #########################################

# data "kubectl_file_documents" "aws-auth-cm" {
#     content = templatefile("${path.module}/configs/aws-auth-cm.yaml", {
#       node_pool_role_arn = "${aws_iam_role.node.arn}",
#       current_aws_user_arn = "${data.aws_caller_identity.current.arn}"
#       current_aws_username = "${data.aws_caller_identity.current.user_id}"
#       }
#     )
# }

# resource "kubectl_manifest" "aws-auth" {
#   provider = kubectl.kubectl-aws
#   for_each  = data.kubectl_file_documents.aws-auth-cm.manifests
#   yaml_body = each.value
#   depends_on = [
#     module.eks,
#     aws_iam_role.node
#   ]
# }

##################################### AWS GP3 STORAGE CLASS #########################################

# data "kubectl_file_documents" "aws-ebs-gp3" {
#     content = templatefile("${path.module}/configs/ebs-gp3.yaml", {
#       k8s_aws_region = var.aws_region
#     })
# }

# resource "kubectl_manifest" "aws-ebs" {
#   provider = kubectl.kubectl-aws
#   for_each  = data.kubectl_file_documents.aws-ebs-gp3.manifests
#   yaml_body = each.value
#   depends_on = [
#     module.eks
#   ]
# }

##################################### AWS CLUSTER ENCRYPTION KEYS #########################################

resource "aws_kms_key" "eks" {
  description             = "EKS Secret Encryption Key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

##################################### AWS CLUSTER EKS SETUP #########################################

# module "eks" {
#   source  = "terraform-aws-modules/eks/aws"
#   version = "~> 18.0"
#   cluster_name    = local.eks_cluster_name
#   cluster_version = "1.30"
#   subnet_ids = module.vpc.private_subnets
#   vpc_id = module.vpc.vpc_id
#   cluster_encryption_config = [
#     {
#         provider_key_arn = "${aws_kms_key.eks.arn}"
#         resources = ["secrets"]
#     }
#   ]
# }

##################################### AWS CLUSTER PLUGINS #########################################

# resource "aws_eks_addon" "csi-driver" {
#   cluster_name = module.eks.cluster_name
#   addon_name   = "aws-ebs-csi-driver"
#   resolve_conflicts_on_update = "PRESERVE"
#   depends_on = [ aws_eks_node_group.default-node-pool]
# }

# resource "aws_eks_addon" "vpc-cni" {
#   cluster_name = module.eks.cluster_name
#   addon_name   = "vpc-cni"
#   resolve_conflicts_on_update = "PRESERVE"
# }

# resource "aws_eks_addon" "coredns" {
#   cluster_name = module.eks.cluster_name
#   addon_name   = "coredns"
#   resolve_conflicts_on_update = "PRESERVE"
#   depends_on = [ aws_eks_node_group.default-node-pool ]
# }

# resource "aws_eks_addon" "kube-proxy" {
#   cluster_name = module.eks.cluster_name
#   addon_name   = "kube-proxy"
#   resolve_conflicts_on_update = "PRESERVE"
# }

##################################### AWS CLUSTER NODE POOLS #########################################

# resource "aws_eks_node_group" "default-node-pool" {
#   cluster_name    = module.eks.cluster_name
#   ami_type        = "AL2_x86_64"
#   version         = "1.30"
#   node_group_name = "${local.eks_cluster_name}-default-node-pool"
#   node_role_arn   = aws_iam_role.node.arn
#   subnet_ids      = module.vpc.public_subnets
#   disk_size       = 500
#   instance_types  = ["t3.large"]
#   scaling_config {
#     desired_size = 2
#     max_size     = 5
#     min_size     = 2
#   }
#   update_config {
#     max_unavailable = 1
#   }
#   remote_access {
#     ec2_ssh_key = aws_key_pair.bastion.key_name
#     source_security_group_ids = [module.vpc.default_security_group_id]
#   }
#   depends_on = [ 
#     aws_eks_addon.vpc-cni,
#     aws_eks_addon.kube-proxy
#   ]
#   tags = {
#     "cluster" = local.eks_cluster_name,
#     "pool" = "default",
#     "role" = "cluster_node"
#   }
# }

# resource "aws_eks_node_group" "arm-default-node-pool" {
#   cluster_name    = module.eks.cluster_name
#   ami_type        = "AL2_ARM_64"
#   version         = "1.30"
#   node_group_name = "${local.eks_cluster_name}-arm-default-node-pool"
#   node_role_arn   = aws_iam_role.node.arn
#   subnet_ids      = module.vpc.public_subnets
#   disk_size       = 500
#   instance_types  = ["t4g.large"]
#   scaling_config {
#     desired_size = 4
#     max_size     = 5
#     min_size     = 2
#   }
#   update_config {
#     max_unavailable = 1
#   }
#   remote_access {
#     ec2_ssh_key = aws_key_pair.bastion.key_name
#     source_security_group_ids = [module.vpc.default_security_group_id]
#   }
#   depends_on = [ 
#     aws_eks_addon.vpc-cni,
#     aws_eks_addon.kube-proxy
#   ]
#   tags = {
#     "cluster" = local.eks_cluster_name,
#     "pool" = "arm-default",
#     "role" = "cluster_node"
#   }
#   taint {
#     key    = "arch"
#     value  = "arm64"
#     effect = "NO_SCHEDULE"  # or "NoExecute" based on your requirement
#   }

# }

##################################### AWS PUBLIC ECR #########################################
provider "aws" {
  alias = "us_east_1"
  region = "us-east-1"
  access_key = var.aws_key
  secret_key = var.aws_secret
}
data "aws_caller_identity" "current" {}

module "ecr" {
  providers = {
    aws = aws.us_east_1
  }
  source = "terraform-aws-modules/ecr/aws"

  repository_name = "centene-poc"
  repository_type = "private"
  repository_read_write_access_arns = [data.aws_caller_identity.current.arn, aws_iam_role.node.arn]
  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last 30 images",
        selection = {
          tagStatus     = "tagged",
          tagPrefixList = ["v"],
          countType     = "imageCountMoreThan",
          countNumber   = 30
        },
        action = {
          type = "expire"
        }
      }
    ]
  })
  tags = {
    env = "dev"
    Owner = "Shiv"
    Team = "STS"
  }
}
