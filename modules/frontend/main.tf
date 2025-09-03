resource "kubernetes_deployment" "frontend" {
    metadata {
      name = var.frontend_name
      namespace = var.namespace
      labels = {
        app = var.frontend_name
      }
    }
    spec {
      replicas = var.frontend_replicas

      selector {
        match_labels = {
          app = var.frontend_name
        }
      }

      template {
        metadata {
          labels = {
            app = var.frontend_name
          }
        }
        spec {
          container {
            name = var.frontend_name
            image = var.frontend_image

            port {
              container_port = 80
            }

            readiness_probe {
              http_get {
                path = "/"
                port = 80
              }
              initial_delay_seconds = 5
              period_seconds = 10
              timeout_seconds = 2
              failure_threshold = 3
            }

            resources {
                requests = {
                  memory = "64Mi"
                  cpu= "100m"
                }
                limits = {
                  memory = "128Mi"
                  cpu = "500m"
                }
            }
          }
        }
      }
    }
  
}

resource "kubernetes_service" "frontend" {
    metadata {
      name = var.frontend_name
      namespace = var.namespace
    }

    spec {
      selector = {
        app = var.frontend_name
      }
      port {
        port = 80
        target_port = 80
      }
    }
  
}