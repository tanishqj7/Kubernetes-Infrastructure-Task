resource "kubernetes_secret" "backend" {
    metadata {
      name = "backend-secrets"
      namespace = var.namespace
      labels =  {
        app = var.backend_name
      }
    }
    type = "Opaque"
    data = {
      "JWT_SECRET_KEY" = "RjhCVlA5ZW9kSEw4blM3enhLOUhESzlpYmV6NUJya2lHbTdrWEJ3UEU1eGdqRml3cEp4eVFTZUx4bklwUGZZWVpHZXFSMVE1T1RCZ2R4UnFUOEtYOUE9PQo"
    } 
}

resource "kubernetes_deployment" "backend_deployment" {
    metadata {
      name = var.backend_name
      namespace = var.namespace
      labels = {
        app = var.backend_name
      }
    }
    spec {
      replicas = var.backend_replicas
      selector {
        match_labels = {
            app= var.backend_name
        }
      }
      template {
        metadata {
          labels = {
            app = var.backend_name
          }
        }
        spec {
          container {
            name = var.backend_name
            image = var.backend_image
            port {
              container_port = var.flask_port
            }
            readiness_probe {
              exec {
                command = [ "sh", "-c", "nc -z postgres 5432" ]
              }
              initial_delay_seconds = 15
              period_seconds = 10
              timeout_seconds = 5
              failure_threshold = 3
            }
            env {
              name = "DATABASE_URL"
              value_from {
                config_map_key_ref {
                  name = var.app_config_name
                  key = "DATABASE_URL"
                }
              }
            }
            env {
              name = "JWT_SECRET_KEY"
              value_from {
                secret_key_ref {
                  name = kubernetes_secret.backend.metadata[0].name
                  key = "JWT_SECRET_KEY"
                }
              }
            }
          }
        }
      }
    }
}


resource "kubernetes_service" "backend" {
  metadata {
    name = var.backend_name
    namespace = var.namespace
    labels = {
      app = var.backend_name
    }
  }
  spec {
    selector = {
      app= var.backend_name
    }
    port {
      port = var.flask_port
      target_port = var.flask_port
    }
  }
}