data "aws_ecr_authorization_token" "auth" {
    provider = aws.us_east_1
    registry_id = module.ecr.repository_registry_id
}

resource "docker_image" "auto-dr-client" {
  name = "${module.ecr.repository_url}:latest"
  build {
    context = "./clients"
    tag     = ["latest"]
    dockerfile = "Dockerfile"
  }

  triggers = {
    dir_sha1 = sha1(join("", [for f in fileset(path.module, "./clients/*") : filesha1(f)]))
  }
}

# resource "docker_registry_image" "auto-dr-client" {
#   name = docker_image.auto-dr-client.name
#   keep_remotely = true
# }

# resource "docker_image" "healthchecker" {
#   name = "${module.ecr.repository_url}:healthchecker"
#   build {
#     context = "./healthcheck"
#     tag     = ["healthchecker"]
#     dockerfile = "Dockerfile"
#   }

  # triggers = {
  #   dir_sha1 = sha1(join("", [for f in fileset(path.module, "./healthcheck/*") : filesha1(f)]))
  # }
# }

# resource "docker_registry_image" "healthchecker" {
#   name = docker_image.healthchecker.name
#   keep_remotely = true
# }

resource "helm_release" "keda" {
    name = "keda"
    chart = "${path.module}/dependencies/keda"
    create_namespace = true
    namespace = kubernetes_namespace.kafka.metadata[0].name
    recreate_pods = true
    force_update = true
    skip_crds = false
    cleanup_on_fail = true
}

resource "kubernetes_namespace" "kafka" {
  provider = kubernetes.kubernetes-raw
  metadata {
    name = "kafka"
    annotations = {
      "owner" = "local"
      "purpose" = "dr-test"
    }
  }
}

resource "kubernetes_config_map" "kafka-primary" {
  provider = kubernetes.kubernetes-raw
  metadata {
    name = "kafka-client-primary"
    namespace = kubernetes_namespace.kafka.metadata[0].name
    annotations = {
        "owner" = "local"
        "purpose" = "dr-test"
    }
  }
  data = {
    "KAFKA_TOPIC" = confluent_kafka_topic.primary.topic_name
    "MIRROR_KAFKA_TOPIC" = "west-auto-dr"
    "KAFKA_CLUSTER_ENV" = "primary"
    "KAFKA_CONSUMER_OFFSET_RESET" = "earliest"
    "KAFKA_BOOTSTRAP" = confluent_kafka_cluster.primary.bootstrap_endpoint
    "KAFKA_USERNAME" = confluent_api_key.cluster-api-key-primary.id
    "KAFKA_PASSWORD" = confluent_api_key.cluster-api-key-primary.secret
  }
}

resource "kubernetes_config_map" "kafka-secondary" {
  provider = kubernetes.kubernetes-raw
  metadata {
    name = "kafka-client-secondary"
    namespace = kubernetes_namespace.kafka.metadata[0].name
    annotations = {
        "owner" = "local"
        "purpose" = "dr-test"
    }
  }
  data = {
    "KAFKA_TOPIC" = confluent_kafka_topic.secondary.topic_name
    "MIRROR_KAFKA_TOPIC" = "east-auto-dr"
    "KAFKA_CLUSTER_ENV" = "secondary"
    "KAFKA_CONSUMER_OFFSET_RESET" = "latest"
    "KAFKA_BOOTSTRAP" = confluent_kafka_cluster.secondary.bootstrap_endpoint
    "KAFKA_USERNAME" = confluent_api_key.cluster-api-key-secondary.id
    "KAFKA_PASSWORD" = confluent_api_key.cluster-api-key-secondary.secret
  }
}

# # Producers

## Producer Primary
# data "kubectl_file_documents" "producer-primary" {
#     content = templatefile("${path.module}/yaml/deployment/producer.yaml", {
#       "namespace" = kubernetes_namespace.kafka.metadata[0].name
#       "env_config_map" = kubernetes_config_map.kafka-primary.metadata[0].name
#       "image" = "829250931565.dkr.ecr.us-east-1.amazonaws.com/centene-poc:latest"
#     })
# }

# resource "kubectl_manifest" "producer-primary" {
#     provider = kubectl.kubectl-aws
#     for_each  = data.kubectl_file_documents.producer-primary.manifests
#     yaml_body = each.value
#     # depends_on = [ docker_image.auto-dr-client, kubernetes_namespace.kafka, kubernetes_config_map.kafka-primary ]
# }

# ## Producer Secondary
# data "kubectl_file_documents" "producer-secondary" {
#     content = templatefile("${path.module}/yaml/deployment/producer-dr.yaml", {
#       "namespace" = kubernetes_namespace.kafka.metadata[0].name
#       "env_config_map" = kubernetes_config_map.kafka-secondary.metadata[0].name
#       "image" = "829250931565.dkr.ecr.us-east-1.amazonaws.com/centene-poc:latest"
#     })
# }

# resource "kubectl_manifest" "producer-secondary" {
#     for_each  = data.kubectl_file_documents.producer-secondary.manifests
#     yaml_body = each.value
#     # depends_on = [ docker_image.auto-dr-client ]
# }

# ## Consumer Primary
# data "kubectl_file_documents" "consumer-primary" {
#     content = templatefile("${path.module}/yaml/deployment/consumer.yaml", {
#       "namespace" = kubernetes_namespace.kafka.metadata[0].name
#       "env_config_map" = kubernetes_config_map.kafka-primary.metadata[0].name
#       "image" = "829250931565.dkr.ecr.us-east-1.amazonaws.com/centene-poc:latest"
#     })
# }

# resource "kubectl_manifest" "consumer-primary" {
#     for_each  = data.kubectl_file_documents.consumer-primary.manifests
#     yaml_body = each.value
#     # depends_on = [ docker_image.auto-dr-client ]
# }

# ## Consumer Secondary
# data "kubectl_file_documents" "consumer-secondary" {
#     content = templatefile("${path.module}/yaml/deployment/consumer-dr.yaml", {
#       "namespace" = kubernetes_namespace.kafka.metadata[0].name
#       "env_config_map" = kubernetes_config_map.kafka-secondary.metadata[0].name
#       "image" = "829250931565.dkr.ecr.us-east-1.amazonaws.com/centene-poc:latest"
#     })
# }

# resource "kubectl_manifest" "consumer-secondary" {
#     for_each  = data.kubectl_file_documents.consumer-secondary.manifests
#     yaml_body = each.value
#     # depends_on = [ docker_image.auto-dr-client ]
# }

## Healthcheck Cron
# data "kubectl_file_documents" "healthcheck-cron" {
#     content = templatefile("${path.root}/yaml/healthcheck-cron.yaml", {
#       "namespace" = kubernetes_namespace.kafka.metadata[0].name
#       "image" = "829250931565.dkr.ecr.us-east-1.amazonaws.com/centene-poc:healthchecker"
#       "kafka_config" = kubernetes_config_map.kafka_healthcheck_config.metadata[0].name
#     })
# }

# resource "kubectl_manifest" "healthcheck-cron" {
#     for_each  = data.kubectl_file_documents.healthcheck-cron.manifests
#     yaml_body = each.value
#     # depends_on = [ docker_image.auto-dr-client ]
# }


## Scalar Objects

# data "kubectl_file_documents" "scalar-objects" {
#     content = templatefile("${path.root}/healthcheck/keda/scalar-objects.yaml", {
#       "keda_namespace" = helm_release.keda.namespace
#       "client_namespace" = kubernetes_namespace.kafka.metadata[0].name
#       "failover_configmap" = kubernetes_config_map.kafka_failover_config.metadata[0].name
#     })
# }

# resource "kubectl_manifest" "scalar-objects" {
#     for_each  = data.kubectl_file_documents.scalar-objects.manifests
#     yaml_body = each.value
#     depends_on = [ docker_image.auto-dr-client ]
# }

