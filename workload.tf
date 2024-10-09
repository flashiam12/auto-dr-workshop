resource "kubernetes_deployment" "secondary_consumer" {
  provider = kubernetes.kubernetes-raw
  metadata {
    name      = "secondary-consumer"
    namespace = kubernetes_namespace.kafka.metadata[0].name
  }
  spec {
    replicas = 0
    selector {
      match_labels = {
        app = "secondary-consumer-client"
      }
    }
    template {
      metadata {
        labels = {
          app = "secondary-consumer-client"
        }
      }
      spec {
        container {
          name  = "consumer-client"
          image = docker_image.auto-dr-client.name
          image_pull_policy = "IfNotPresent"

          command = [
            "python",
            "consumer.py"
          ]

          env_from {
            config_map_ref {
              name = kubernetes_config_map.kafka-secondary.metadata[0].name
            }
          }

          resources {
            limits =  {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests =  {
              cpu    = "0.125"
              memory = "128Mi"
            }
          }
        }

        toleration {
          key      = "arch"
          operator = "Equal"
          value    = "arm64"
          effect   = "NoSchedule"
        }
      }
    }
  }
}

resource "kubernetes_deployment" "primary_consumer" {
  provider = kubernetes.kubernetes-raw
  metadata {
    name      = "primary-consumer"
    namespace = kubernetes_namespace.kafka.metadata[0].name
  }

  spec {
    replicas = 3

    selector {
      match_labels = {
        app = "primary-consumer-client"
      }
    }

    template {
      metadata {
        labels = {
          app = "primary-consumer-client"
        }
      }

      spec {
        container {
          name  = "consumer-client"
          image = docker_image.auto-dr-client.name
          image_pull_policy = "IfNotPresent"

          command = [
            "python",
            "consumer.py"
          ]

          env_from {
            config_map_ref {
              name = kubernetes_config_map.kafka-primary.metadata[0].name
            }
          }

          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }

            requests = {
              cpu    = "0.125"
              memory = "128Mi"
            }
          }
        }

        toleration {
          key      = "arch"
          operator = "Equal"
          value    = "arm64"
          effect   = "NoSchedule"
        }
      }
    }
  }
}

resource "kubernetes_deployment" "secondary_producer" {
  provider = kubernetes.kubernetes-raw
  metadata {
    name      = "secondary-producer"
    namespace = kubernetes_namespace.kafka.metadata[0].name
  }

  spec {
    replicas = 0

    selector {
      match_labels = {
        app = "secondary-producer-client"
      }
    }

    template {
      metadata {
        labels = {
          app = "secondary-producer-client"
        }
      }

      spec {
        container {
          name  = "producer-client"
          image = docker_image.auto-dr-client.name
          image_pull_policy = "IfNotPresent"

          command = [
            "python",
            "producer.py"
          ]

          env_from {
            config_map_ref {
              name = kubernetes_config_map.kafka-secondary.metadata[0].name
            }
          }

          resources {
            limits =  {
              cpu    = "0.5"
              memory = "512Mi"
            }

            requests =  {
              cpu    = "0.125"
              memory = "128Mi"
            }
          }
        }

        toleration {
          key      = "arch"
          operator = "Equal"
          value    = "arm64"
          effect   = "NoSchedule"
        }
      }
    }
  }
}

resource "kubernetes_deployment" "primary_producer" {
  provider = kubernetes.kubernetes-raw
  metadata {
    name      = "primary-producer"
    namespace = kubernetes_namespace.kafka.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "primary-producer-client"
      }
    }

    template {
      metadata {
        labels = {
          app = "primary-producer-client"
        }
      }

      spec {
        container {
          name  = "producer-client"
          image = docker_image.auto-dr-client.name
          image_pull_policy = "IfNotPresent"

          command = [
            "python",
            "producer.py"
          ]

          env_from {
            config_map_ref {
              name = kubernetes_config_map.kafka-primary.metadata[0].name
            }
          }

          resources {
            limits =  {
              cpu    = "0.5"
              memory = "512Mi"
            }

            requests =  {
              cpu    = "0.125"
              memory = "128Mi"
            }
          }
        }

        toleration {
          key      = "arch"
          operator = "Equal"
          value    = "arm64"
          effect   = "NoSchedule"
        }
      }
    }
  }
}