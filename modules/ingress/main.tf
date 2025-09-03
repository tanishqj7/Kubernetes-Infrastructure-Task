resource "kubernetes_ingress_v1" "nginx_ingress" {
    metadata {
      name = "nginx-ingress"
      namespace = var.namespace

      annotations  = {
       "nginx.ingress.kubernetes.io/enable-cors" = "true"
        "nginx.ingress.kubernetes.io/cors-allow-origin" = "*"
        "nginx.ingress.kubernetes.io/cors-allow-methods" = "GET, POST, OPTIONS"
        "nginx.ingress.kubernetes.io/cors-allow-headers" = "Authorization, Content-Type"
      }
    }

    spec {
      rule {
        host = "localhost"
        http {
          path {
            path = "/auth"
            path_type = "Prefix"
            backend {
              service {
                name = var.backend_name
                port {
                    number = var.flask_port
                }
              }
            }
          }
          path {
            path = "/api"
            path_type = "Prefix"
            backend {
              service {
                name = var.backend_name
                port {
                    number = var.flask_port
                }
              }
            }
          }
          path {
            path = "/"
            path_type = "Prefix"
            backend {
              service {
                name = var.frontend_name
                port {
                    number = 80
                }
              }
            }
          }
        }
      }
    }

  
}