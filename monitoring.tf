# resource "kubernetes_namespace" "monitoring" {
#   provider = kubernetes.kubernetes-raw
#   metadata {
#     name = "monitoring"
#     annotations = {
#       "owner" = "local"
#       "purpose" = "dr-test"
#     }
#   }
# }

# resource "helm_release" "prometheus" {
#   name       = "prometheus"
#   chart      = "${path.module}/dependencies/prometheus"
#   namespace  = kubernetes_namespace.monitoring.metadata[0].name
#   cleanup_on_fail = true
#   create_namespace = false
#   values = [templatefile("${path.module}/dependencies/prometheus/values.yaml", 
#             {
#                 "cloud_api_key" = var.cc_cloud_api_key
#                 "cloud_api_secret" = var.cc_cloud_api_secret
#                 "primary_cluster_id" = confluent_kafka_cluster.primary.id
#                 "secondary_cluster_id" = confluent_kafka_cluster.secondary.id
#             }
#             )]
# }

# resource "helm_release" "grafana" {
#   name       = "grafana"
#   chart      = "${path.module}/dependencies/grafana"
#   namespace  = kubernetes_namespace.monitoring.metadata[0].name
#   cleanup_on_fail = true
#   create_namespace = false
#   values = [file("${path.module}/dependencies/grafana/values.yaml")]
#   set {
#     name = "adminUser"
#     value = "admin"
#   }
#   set {
#     name = "adminPassword"
#     value = "confluent"
#   }
# }