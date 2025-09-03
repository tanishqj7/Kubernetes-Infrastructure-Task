# resource "kubernetes_config_map" "postgres_config" {
#   metadata {
#     name = "${var.postgres_name}-config"
#     namespace = var.namespace
#     labels = {
#       app = var.postgres_name
#     }
#   }

#   data ={
#     POSTGRES_DB = var.db_name
#     POSTGRES_USER = var.db_user
#     PGDATA = var.pgdata
#   }
# }





# resource "kubernetes_secret" "postgres_secret" {
#   metadata {
#     name = "${var.postgres_name}-secret"
#     namespace = var.namespace
#     labels = {
#       "app" = var.postgres_name
#     }
#   }
#   data = {
#     POSTGRES_PASSWORD = base64encode(var.db_password)
#     username          = base64encode(var.db_user)
#     database          = base64encode(var.db_name)

#   }
# }

# resource "kubernetes_config_map" "mysql_initdb" {
#   metadata {
#     name      = "mysql-initdb"
#     namespace = var.namespace
#   }

#   data = {
#     "init.sql" = file("${path.module}/init.sql")  
#   }
# } 


# resource "kubernetes_stateful_set" "postgres" {
#     metadata {
#       name = var.postgres_name
#       namespace = var.namespace
#     }

#     spec {
#       service_name =  var.postgres_name
#       replicas = var.postgres_replicas

#       selector {
#         match_labels = {
#           app = var.postgres_name
#         }
#       }
#       template {
#         metadata {
#             labels = {
#                 app = var.postgres_name
#             }
#         }
#         spec {
#             container {
#               name = var.postgres_name
#               image = var.postgres_image
#               port {
#                 container_port = 5432
#               }
#               env {
#                 name = "POSTFRES_DB"
#                 value_from {
#                   config_map_key_ref {
#                         name = kubernetes_config_map.postgres_config.metadata[0].name
#                         key = "POSTGRES_DB"
#                   }
#                 }
#               }
#               env {
#                 name = "POSTFRES_USER"
#                 value_from {
#                   config_map_key_ref {
#                         name = kubernetes_config_map.postgres_config.metadata[0].name
#                         key = "POSTGRES_USER"
#                   }
#                 }
#               }
#               env {
#                 name = "POSTFRES_PASSWORD"
#                 value_from {
#                   config_map_key_ref {
#                         name = kubernetes_secret.postgres_secret.metadata[0].name       
#                         key = "POSTGRES_PASSWORD"
#                   }
#                 }
#               }
#               env {
#                 name = "PGDATA"
#                 value_from {
#                   config_map_key_ref {
#                         name = kubernetes_config_map.postgres_config.metadata[0].name
#                         key = "PGDATA"
#                   }
#                 }
#               }

#               volume_mount {
#                 name = "${var.postgres_name}-storage"
#                 mount_path = "/var/lib/postgresql/data"
#               }
#               volume_mount {
#                 name = "mysql-init"
#                 mount_path = "/docker-entrypoint-initdb.d"
#               }
#             }
#             volume {
#                     name = "mysql-init"
#                     config_map {
#                         name = kubernetes_config_map.mysql_initdb.metadata[0].name
#                     }
#                 }
#         }
#       }
#       volume_claim_template {
#         metadata {
#             name = "${var.postgres_name}-storage"
#         }

#         spec {
#             access_modes       = ["ReadWriteOnce"]
#             storage_class_name = var.storage_class

#             resources {
#                 requests = {
#                     storage = var.storage_size
#                 }
#             }
#         }
#     }    
#     }
# }



# resource "kubernetes_service" "postgres" {
#       metadata {
#         name = var.postgres_name
#         namespace = var.namespace
#       }
#       spec {
#         selector = {
#           app = var.postgres_name
#         }
#         port {
#           port = 5432
#           target_port = 5432
#           protocol = "TCP"
#         }
#       }
#     }





resource "kubernetes_config_map" "postgres_config" {
  metadata {
    name      = "${var.postgres_name}-config"
    namespace = var.namespace
    labels = {
      app = var.postgres_name
    }
  }

  data = {
    POSTGRES_DB   = var.db_name
    POSTGRES_USER = var.db_user
    PGDATA        = var.pgdata
  }
}

resource "kubernetes_secret" "postgres_secret" {
  metadata {
    name      = "${var.postgres_name}-secret"
    namespace = var.namespace
    labels = {
      app = var.postgres_name
    }
  }

  data = {
    POSTGRES_PASSWORD = base64encode(var.db_password)
  }
}

resource "kubernetes_config_map" "postgres_initdb" {
  metadata {
    name      = "${var.postgres_name}-initdb"
    namespace = var.namespace
  }

  data = {
    "init.sql" = file("${path.module}/init.sql")
  }
}

resource "kubernetes_stateful_set" "postgres" {
  metadata {
    name      = var.postgres_name
    namespace = var.namespace
  }

  spec {
    service_name = var.postgres_name
    replicas     = var.postgres_replicas

    selector {
      match_labels = {
        app = var.postgres_name
      }
    }

    template {
      metadata {
        labels = {
          app = var.postgres_name
        }
      }

      spec {
        container {
          name  = var.postgres_name
          image = var.postgres_image

          port {
            container_port = 5432
          }

          env {
            name = "POSTGRES_DB"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.postgres_config.metadata[0].name
                key  = "POSTGRES_DB"
              }
            }
          }

          env {
            name = "POSTGRES_USER"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.postgres_config.metadata[0].name
                key  = "POSTGRES_USER"
              }
            }
          }

          env {
            name = "POSTGRES_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.postgres_secret.metadata[0].name
                key  = "POSTGRES_PASSWORD"
              }
            }
          }

          env {
            name = "PGDATA"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.postgres_config.metadata[0].name
                key  = "PGDATA"
              }
            }
          }

          volume_mount {
            name       = "${var.postgres_name}-storage"
            mount_path = "/var/lib/postgresql/data"
          }

          volume_mount {
            name       = "postgres-init"
            mount_path = "/docker-entrypoint-initdb.d"
          }
        }

        volume {
          name = "postgres-init"
          config_map {
            name = kubernetes_config_map.postgres_initdb.metadata[0].name
          }
        }
      }
    }

    volume_claim_template {
      metadata {
        name = "${var.postgres_name}-pvc"
      }

      spec {
        access_modes       = ["ReadWriteOnce"]
        storage_class_name = var.storage_class

        resources {
          requests = {
            storage = var.storage_size
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "postgres" {
  metadata {
    name      = var.postgres_name
    namespace = var.namespace
  }

  spec {
    selector = {
      app = var.postgres_name
    }

    port {
      port        = 5432
      target_port = 5432
      # protocol    = "TCP"
    }
  }
}
