resource "kubernetes_namespace" "app_ns" {
  metadata {
    name = var.namespace
  }
}

module "postgres" {
  source = "./modules/postgres"

  namespace         = var.namespace
  postgres_name     = var.postgres_name
  postgres_image    = var.postgres_image
  postgres_replicas = var.postgres_replicas
  db_name           = var.db_name
  db_user           = var.db_user
  db_password       = var.db_password
  pgdata            = var.pgdata
  storage_class     = var.storage_class
  storage_size      = var.storage_size
}

module "backend" {
  source = "./modules/backend"

  namespace         = var.namespace
  backend_name      = var.backend_name
  backend_image     = var.backend_image
  backend_replicas  = var.backend_replicas
  flask_port        = var.flask_port
  app_config_name   = var.app_config_name
}

module "frontend" {
  source = "./modules/frontend"

  namespace          = var.namespace
  frontend_name      = var.frontend_name
  frontend_image     = var.frontend_image
  frontend_replicas  = var.frontend_replicas
}

module "ingress" {
  source = "./modules/ingress"

  namespace     = var.namespace
  backend_name  = module.backend.backend_service_name
  frontend_name = module.frontend.frontend_service_name
  flask_port    = var.flask_port
}



# resource "kubernetes_config_map" "postgres_config" {
#   metadata {
#     name      = "${var.postgres_name}-config"
#     namespace = var.namespace
#     labels = {
#       app = var.postgres_name
#     }
#   }

#   data = {
#     POSTGRES_DB   = var.db_name
#     POSTGRES_USER = var.db_user
#     PGDATA        = var.pgdata
#   }
# }