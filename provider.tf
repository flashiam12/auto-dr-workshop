terraform {
  required_providers {
    confluent = {
      source = "confluentinc/confluent"
      version = "1.76.0"
    }
    docker = {
      source = "kreuzwerker/docker"
      version = "3.0.2"
    }
    kubectl = {
      source = "gavinbunney/kubectl"
      version = "1.14.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 3.0"
    }                                                                                                              
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"

  registry_auth {
    address = data.aws_ecr_authorization_token.auth.proxy_endpoint
    username = data.aws_ecr_authorization_token.auth.user_name
    password = data.aws_ecr_authorization_token.auth.password
  }
}

provider "http" {}

provider "aws" {
  access_key = var.aws_key
  secret_key = var.aws_secret
  region = var.aws_region
}


# provider "kubectl" {
#   alias = "kubectl-aws"
#   host                   = data.aws_eks_cluster.cluster.endpoint
#   cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
#   token                  = data.aws_eks_cluster_auth.cluster.token
#   load_config_file       = true
# }

# provider "helm" {
#   kubernetes {
#     host                   = data.aws_eks_cluster.cluster.endpoint
#     cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
#     token                  = data.aws_eks_cluster_auth.cluster.token
#   }
# }

provider "kubernetes" {
  alias = "kubernetes-raw"
  # host                   = data.aws_eks_cluster.cluster.endpoint
  # cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  # token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "confluent" {
    cloud_api_key = var.cc_cloud_api_key
    cloud_api_secret = var.cc_cloud_api_secret
}

variable "cc_cloud_api_key" {}
variable "cc_cloud_api_secret" {}
variable "cc_env" {}
variable "aws_key" {}
variable "aws_secret" {}
variable "aws_region" {}
