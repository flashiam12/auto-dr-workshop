output "primary_cluster" {
  sensitive = false
  value = {
    region = "us-east-1"
    bootstrap_endpoint = confluent_kafka_cluster.primary.bootstrap_endpoint
    cluster_id = confluent_kafka_cluster.primary.id
    cluster_api_key = confluent_api_key.cluster-api-key-primary.id
    cluster_api_secret = nonsensitive(confluent_api_key.cluster-api-key-primary.secret)
    topic = confluent_kafka_topic.primary.topic_name
    mirror_topic = "west-auto-dr"
  }
}

output "secondary_cluster" {
  sensitive = false
  value = {
    region = "us-west-2"
    bootstrap_endpoint = confluent_kafka_cluster.secondary.bootstrap_endpoint
    cluster_id = confluent_kafka_cluster.secondary.id
    cluster_api_key = confluent_api_key.cluster-api-key-secondary.id
    cluster_api_secret = nonsensitive(confluent_api_key.cluster-api-key-secondary.secret)
    topic = confluent_kafka_topic.secondary.topic_name
    mirror_topic = "east-auto-dr"
  }
}