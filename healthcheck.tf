# resource "kubernetes_config_map" "kafka_failover_config" {
#   provider = kubernetes.kubernetes-raw
#   metadata {
#     name      = "kafka-failover-config"
#     namespace = kubernetes_namespace.kafka.metadata[0].name  # Replace with your namespace variable or hardcode the value
#   }

#   data = {
#     primary-producer-replicas  = "1"
#     primary-consumer-replicas  = "1"
#     secondary-producer-replicas = "0"
#     secondary-consumer-replicas = "0"
#     connection-state           = "HEALTHY"  # Can also be "FAILOVER" or "FAILBACK"
#   }
# }

# resource "kubernetes_config_map" "kafka_healthcheck_config" {
#   provider = kubernetes.kubernetes-raw
#   metadata {
#     name      = "kafka-healthcheck-config"
#     namespace = kubernetes_namespace.kafka.metadata[0].name  # Replace with your namespace variable or hardcode the value
#   }

#   data = {
#     primary-broker                = confluent_kafka_cluster.primary.bootstrap_endpoint
#     secondary-broker              = confluent_kafka_cluster.secondary.bootstrap_endpoint
#     healthcheck-topic             = confluent_kafka_topic.primary-healthcheck.topic_name
#     failover-configmap            = kubernetes_config_map.kafka_failover_config.metadata[0].name
#     failover-configmap-namespace  = kubernetes_config_map.kafka_failover_config.metadata[0].namespace

#     "producer-primary.properties" = <<EOF

# bootstrap.servers=${confluent_kafka_cluster.primary.bootstrap_endpoint}
# security.protocol=SASL_SSL
# sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='${confluent_api_key.cluster-api-key-primary.id}' password='${confluent_api_key.cluster-api-key-primary.secret}';
# sasl.mechanism=PLAIN

# client.dns.lookup=use_all_dns_ips

# session.timeout.ms=45000

# acks=all

# EOF

#     "producer-secondary.properties" = <<EOF
# bootstrap.servers=${confluent_kafka_cluster.secondary.bootstrap_endpoint}
# security.protocol=SASL_SSL
# sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='${confluent_api_key.cluster-api-key-secondary.id}' password='${confluent_api_key.cluster-api-key-secondary.secret}';
# sasl.mechanism=PLAIN

# client.dns.lookup=use_all_dns_ips

# session.timeout.ms=45000

# acks=all
# EOF

#     "consumer-primary.properties" = <<EOF
# bootstrap.servers=${confluent_kafka_cluster.primary.bootstrap_endpoint}
# security.protocol=SASL_SSL
# sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='${confluent_api_key.cluster-api-key-primary.id}' password='${confluent_api_key.cluster-api-key-primary.secret}';
# sasl.mechanism=PLAIN

# client.dns.lookup=use_all_dns_ips

# session.timeout.ms=45000

# acks=all
# EOF

#     "consumer-secondary.properties" = <<EOF
# bootstrap.servers=${confluent_kafka_cluster.secondary.bootstrap_endpoint}
# security.protocol=SASL_SSL
# sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='${confluent_api_key.cluster-api-key-secondary.id}' password='${confluent_api_key.cluster-api-key-secondary.secret}';
# sasl.mechanism=PLAIN

# client.dns.lookup=use_all_dns_ips

# session.timeout.ms=45000

# acks=all
# EOF
#   }
# }


# resource "local_file" "consumer-primary" {
#   content = <<EOF
# bootstrap.servers=${confluent_kafka_cluster.primary.bootstrap_endpoint}
# security.protocol=SASL_SSL
# sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='${confluent_api_key.cluster-api-key-primary.id}' password='${confluent_api_key.cluster-api-key-primary.secret}';
# sasl.mechanism=PLAIN

# client.dns.lookup=use_all_dns_ips

# session.timeout.ms=45000

# acks=all
# EOF
#   filename            = "${path.module}/properties/consumer-primary.properties"
#   file_permission    = "0777"
# }

# resource "local_file" "consumer-secondary" {
#   content = <<EOF
# bootstrap.servers=${confluent_kafka_cluster.secondary.bootstrap_endpoint}
# security.protocol=SASL_SSL
# sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='${confluent_api_key.cluster-api-key-secondary.id}' password='${confluent_api_key.cluster-api-key-secondary.secret}';
# sasl.mechanism=PLAIN

# client.dns.lookup=use_all_dns_ips

# session.timeout.ms=45000

# acks=all
# EOF
#   filename            = "${path.module}/properties/consumer-secondary.properties"
#   file_permission    = "0777"
# }

# resource "local_file" "producer-primary" {
#   content = <<EOF

# bootstrap.servers=${confluent_kafka_cluster.primary.bootstrap_endpoint}
# security.protocol=SASL_SSL
# sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='${confluent_api_key.cluster-api-key-primary.id}' password='${confluent_api_key.cluster-api-key-primary.secret}';
# sasl.mechanism=PLAIN

# client.dns.lookup=use_all_dns_ips

# session.timeout.ms=45000

# acks=all

# EOF
#   filename            = "${path.module}/properties/producer-primary.properties"
#   file_permission    = "0777"
# }

# resource "local_file" "producer-secondary" {
#   content = <<EOF
# bootstrap.servers=${confluent_kafka_cluster.secondary.bootstrap_endpoint}
# security.protocol=SASL_SSL
# sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='${confluent_api_key.cluster-api-key-secondary.id}' password='${confluent_api_key.cluster-api-key-secondary.secret}';
# sasl.mechanism=PLAIN

# client.dns.lookup=use_all_dns_ips

# session.timeout.ms=45000

# acks=all
# EOF
#   filename            = "${path.module}/properties/producer-secondary.properties"
#   file_permission    = "0777"
# }