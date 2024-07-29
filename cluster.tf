resource "confluent_service_account" "default" {
  display_name = "centene-poc"
  description  = "Service Account for centene workshop"
}

data "confluent_environment" "default"{
    id = "env-vrv23p"
}

locals {
  cc_primary_network_cidr = "100.64.0.0/16"
  cc_secondary_network_cidr = "192.168.0.0/16"
}

resource "confluent_network" "primay-network-transit-gateway" {
  display_name     = "Primary Network For AWS Transit Gateway"
  cloud            = "AWS"
  region           = "us-east-2"
  cidr             = local.cc_primary_network_cidr
  connection_types = ["TRANSITGATEWAY"]
  environment {
    id = data.confluent_environment.default.id
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "confluent_network" "secondary-network-transit-gateway" {
  display_name     = "Secondary Network For AWS Transit Gateway"
  cloud            = "AWS"
  region           = "us-east-2"
  cidr             = local.cc_secondary_network_cidr
  connection_types = ["TRANSITGATEWAY"]
  environment {
    id = data.confluent_environment.default.id
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "confluent_transit_gateway_attachment" "primary" {
  display_name = "AWS Primary Network Transit Gateway Attachment"
  aws {
    ram_resource_share_arn = module.tgw.ram_resource_share_id
    transit_gateway_id     = module.tgw.ec2_transit_gateway_id
    routes                 = [module.vpc.vpc_cidr_block, local.cc_secondary_network_cidr]
  }
  environment {
    id = data.confluent_environment.default.id
  }
  network {
    id = confluent_network.primay-network-transit-gateway.id
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "confluent_transit_gateway_attachment" "secondary" {
  display_name = "AWS Secondary Network Transit Gateway Attachment"
  aws {
    ram_resource_share_arn = module.tgw.ram_resource_share_id
    transit_gateway_id     = module.tgw.ec2_transit_gateway_id
    routes                 = [module.vpc.vpc_cidr_block, local.cc_primary_network_cidr]
  }
  environment {
    id = data.confluent_environment.default.id
  }
  network {
    id = confluent_network.secondary-network-transit-gateway.id
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "confluent_kafka_cluster" "primary" {
  display_name = "centene-primary"
  availability = "SINGLE_ZONE"
  cloud        = "AWS"
  region       = "us-east-2"
  dedicated {
    cku = 2
  }
  network {
    id = confluent_network.primay-network-transit-gateway.id
  }


  environment {
    id = data.confluent_environment.default.id
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "confluent_kafka_cluster" "secondary" {
  display_name = "centene-secondary"
  availability = "SINGLE_ZONE"
  cloud        = "AWS"
  region       = "us-east-2"
  dedicated {
    cku = 2
  }
  network {
    id = confluent_network.secondary-network-transit-gateway.id
  }

  environment {
    id = data.confluent_environment.default.id
  }

  lifecycle {
    prevent_destroy = false
  }
}



resource "confluent_role_binding" "cluster-admin-primary" {
  principal   = "User:${confluent_service_account.default.id}"
  role_name   = "CloudClusterAdmin"
  crn_pattern = confluent_kafka_cluster.primary.rbac_crn
}

resource "confluent_role_binding" "cluster-admin-secondary" {
  principal   = "User:${confluent_service_account.default.id}"
  role_name   = "CloudClusterAdmin"
  crn_pattern = confluent_kafka_cluster.secondary.rbac_crn
}

resource "confluent_role_binding" "topic-write-primary" {
  principal   = "User:${confluent_service_account.default.id}"
  role_name   = "DeveloperWrite"
  crn_pattern = "${confluent_kafka_cluster.primary.rbac_crn}/kafka=${confluent_kafka_cluster.primary.id}/topic=*"
}

resource "confluent_role_binding" "topic-write-secondary" {
  principal   = "User:${confluent_service_account.default.id}"
  role_name   = "DeveloperWrite"
  crn_pattern = "${confluent_kafka_cluster.secondary.rbac_crn}/kafka=${confluent_kafka_cluster.secondary.id}/topic=*"
}

resource "confluent_role_binding" "topic-read-primary" {
  principal   = "User:${confluent_service_account.default.id}"
  role_name   = "DeveloperRead"
  crn_pattern = "${confluent_kafka_cluster.primary.rbac_crn}/kafka=${confluent_kafka_cluster.primary.id}/topic=*"
}

resource "confluent_role_binding" "topic-read-secondary" {
  principal   = "User:${confluent_service_account.default.id}"
  role_name   = "DeveloperRead"
  crn_pattern = "${confluent_kafka_cluster.secondary.rbac_crn}/kafka=${confluent_kafka_cluster.secondary.id}/topic=*"
}


resource "confluent_api_key" "cluster-api-key-primary" {
  display_name = "primary-kafka-api-key"
  description  = "Kafka API Key that is owned by centene service account"
  owner {
    id          = confluent_service_account.default.id
    api_version = confluent_service_account.default.api_version
    kind        = confluent_service_account.default.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.primary.id
    api_version = confluent_kafka_cluster.primary.api_version
    kind        = confluent_kafka_cluster.primary.kind

    environment {
      id = data.confluent_environment.default.id
    }
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "confluent_kafka_topic" "primary" {
  kafka_cluster {
    id = confluent_kafka_cluster.primary.id
  }
  topic_name         = "auto-dr"
  rest_endpoint      = confluent_kafka_cluster.primary.rest_endpoint
  credentials {
    key    = confluent_api_key.cluster-api-key-primary.id
    secret = confluent_api_key.cluster-api-key-primary.secret
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "confluent_kafka_topic" "primary-healthcheck" {
  kafka_cluster {
    id = confluent_kafka_cluster.primary.id
  }
  topic_name         = "healthcheck"
  rest_endpoint      = confluent_kafka_cluster.primary.rest_endpoint
  credentials {
    key    = confluent_api_key.cluster-api-key-primary.id
    secret = confluent_api_key.cluster-api-key-primary.secret
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "confluent_api_key" "cluster-api-key-secondary" {
  display_name = "secondary-kafka-api-key"
  description  = "Kafka API Key that is owned by centene service account"
  owner {
    id          = confluent_service_account.default.id
    api_version = confluent_service_account.default.api_version
    kind        = confluent_service_account.default.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.secondary.id
    api_version = confluent_kafka_cluster.secondary.api_version
    kind        = confluent_kafka_cluster.secondary.kind

    environment {
      id = data.confluent_environment.default.id
    }
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "confluent_kafka_topic" "secondary" {
  kafka_cluster {
    id = confluent_kafka_cluster.secondary.id
  }
  topic_name         = "auto-dr"
  rest_endpoint      = confluent_kafka_cluster.secondary.rest_endpoint
  credentials {
    key    = confluent_api_key.cluster-api-key-secondary.id
    secret = confluent_api_key.cluster-api-key-secondary.secret
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "confluent_kafka_topic" "secondary-healthcheck" {
  kafka_cluster {
    id = confluent_kafka_cluster.secondary.id
  }
  topic_name         = "healthcheck"
  rest_endpoint      = confluent_kafka_cluster.secondary.rest_endpoint
  credentials {
    key    = confluent_api_key.cluster-api-key-secondary.id
    secret = confluent_api_key.cluster-api-key-secondary.secret
  }

  lifecycle {
    prevent_destroy = false
  }
}


resource "confluent_cluster_link" "east-to-west" {
  link_name = "bidirectional-link"
  link_mode = "BIDIRECTIONAL"
  config = {
    "cluster.link.prefix" = "west-"
    "consumer.offset.sync.enable" = "true"
    "consumer.offset.sync.ms" = 1000
    "topic.config.sync.ms" = 1000
  }
  local_kafka_cluster {
    id            = confluent_kafka_cluster.primary.id
    rest_endpoint = confluent_kafka_cluster.primary.rest_endpoint
    credentials {
      key    = confluent_api_key.cluster-api-key-primary.id
      secret = confluent_api_key.cluster-api-key-primary.secret
    }
  }

  remote_kafka_cluster {
    id                 = confluent_kafka_cluster.secondary.id
    bootstrap_endpoint = confluent_kafka_cluster.secondary.bootstrap_endpoint
    credentials {
      key    = confluent_api_key.cluster-api-key-secondary.id
      secret = confluent_api_key.cluster-api-key-secondary.secret
    }
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "confluent_kafka_mirror_topic" "from-east" {
  mirror_topic_name = "east-auto-dr"
  source_kafka_topic {
    topic_name = confluent_kafka_topic.primary.topic_name
  }
  cluster_link {
    link_name = confluent_cluster_link.east-to-west.link_name
  }
  kafka_cluster {
    id            = confluent_kafka_cluster.secondary.id
    rest_endpoint = confluent_kafka_cluster.secondary.rest_endpoint
    credentials {
      key    = confluent_api_key.cluster-api-key-secondary.id
      secret = confluent_api_key.cluster-api-key-secondary.secret
    }
  }

  depends_on = [
    confluent_cluster_link.east-to-west,
    confluent_cluster_link.west-to-east,
    confluent_kafka_topic.primary
  ]
}

resource "confluent_cluster_link" "west-to-east" {
  link_name = "bidirectional-link"
  link_mode = "BIDIRECTIONAL"
  config = {
    "cluster.link.prefix" = "east-"
    "consumer.offset.sync.enable" = "true"
    "consumer.offset.sync.ms" = 1000
    "topic.config.sync.ms" = 1000
  }
  local_kafka_cluster {
    id            = confluent_kafka_cluster.secondary.id
    rest_endpoint = confluent_kafka_cluster.secondary.rest_endpoint
    credentials {
      key    = confluent_api_key.cluster-api-key-secondary.id
      secret = confluent_api_key.cluster-api-key-secondary.secret
    }
  }

  remote_kafka_cluster {
    id                 = confluent_kafka_cluster.primary.id
    bootstrap_endpoint = confluent_kafka_cluster.primary.bootstrap_endpoint
    credentials {
      key    = confluent_api_key.cluster-api-key-primary.id
      secret = confluent_api_key.cluster-api-key-primary.secret
    }
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "confluent_kafka_mirror_topic" "from-west" {
  mirror_topic_name = "west-auto-dr"
  source_kafka_topic {
    topic_name = confluent_kafka_topic.secondary.topic_name
  }
  cluster_link {
    link_name = confluent_cluster_link.west-to-east.link_name
  }
  kafka_cluster {
    id            = confluent_kafka_cluster.primary.id
    rest_endpoint = confluent_kafka_cluster.primary.rest_endpoint
    credentials {
      key    = confluent_api_key.cluster-api-key-primary.id
      secret = confluent_api_key.cluster-api-key-primary.secret
    }
  }

  depends_on = [
    confluent_cluster_link.east-to-west,
    confluent_cluster_link.west-to-east, 
    confluent_kafka_topic.secondary
  ]
}
