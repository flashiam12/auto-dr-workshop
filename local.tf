data "aws_ecr_authorization_token" "auth" {
    provider = aws.us_east_1
    registry_id = module.ecr.repository_registry_id
}


resource "random_id" "auto-dr-client" {
  byte_length = 8
}

resource "docker_image" "auto-dr-client" {
  name = "${module.ecr.repository_url}:${random_id.auto-dr-client.hex}"
  build {
    context = "./clients"
    tag     = [random_id.auto-dr-client.hex]
    dockerfile = "Dockerfile"
  }

  triggers = {
    dir_sha1 = sha1(join("", [for f in fileset(path.module, "./clients/*") : filesha1(f)]))
  }
}

resource "docker_registry_image" "auto-dr-client" {
  name = docker_image.auto-dr-client.name
  keep_remotely = true
}

# resource "kubernetes_namespace" "kafka" {
#   provider = kubernetes.kubernetes-raw
#   metadata {
#     name = "kafka"
#     annotations = {
#       "owner" = "local"
#       "purpose" = "dr-test"
#     }
#   }
# }

# resource "kubernetes_config_map" "kafka-primary" {
#   provider = kubernetes.kubernetes-raw
#   metadata {
#     name = "kafka-client-primary"
#     namespace = kubernetes_namespace.kafka.metadata[0].name
#     annotations = {
#         "owner" = "local"
#         "purpose" = "dr-test"
#     }
#   }
#   data = {
#     "KAFKA_TOPIC" = confluent_kafka_topic.primary.topic_name
#     "MIRROR_KAFKA_TOPIC" = "west-auto-dr"
#     "KAFKA_CLUSTER_ENV" = "primary"
#     "KAFKA_CONSUMER_OFFSET_RESET" = "earliest"
#     "KAFKA_BOOTSTRAP" = confluent_kafka_cluster.primary.bootstrap_endpoint
#     "KAFKA_USERNAME" = confluent_api_key.cluster-api-key-primary.id
#     "KAFKA_PASSWORD" = confluent_api_key.cluster-api-key-primary.secret
#   }
# }

# resource "kubernetes_config_map" "kafka-secondary" {
#   provider = kubernetes.kubernetes-raw
#   metadata {
#     name = "kafka-client-secondary"
#     namespace = kubernetes_namespace.kafka.metadata[0].name
#     annotations = {
#         "owner" = "local"
#         "purpose" = "dr-test"
#     }
#   }
#   data = {
#     "KAFKA_TOPIC" = confluent_kafka_topic.secondary.topic_name
#     "MIRROR_KAFKA_TOPIC" = "east-auto-dr"
#     "KAFKA_CLUSTER_ENV" = "secondary"
#     "KAFKA_CONSUMER_OFFSET_RESET" = "latest"
#     "KAFKA_BOOTSTRAP" = confluent_kafka_cluster.secondary.bootstrap_endpoint
#     "KAFKA_USERNAME" = confluent_api_key.cluster-api-key-secondary.id
#     "KAFKA_PASSWORD" = confluent_api_key.cluster-api-key-secondary.secret
#   }
# }