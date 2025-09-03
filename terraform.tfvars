# Namespace
namespace = "myapp"

# Postgres
postgres_name     = "postgres"
postgres_image    = "postgres:15"
postgres_replicas = 1
db_name           = "kube"
db_user           = "postgres"
db_password       = "postgres"
pgdata            = "/var/lib/postgresql/data/pgdata"
storage_class     = "standard"
storage_size      = "1Gi"
app_config_name = "postgres-config"

# Backend
backend_name      = "backend"
backend_image     = "tanishqjaiswal/flask-backend:v10"
backend_replicas  = 1
flask_port        = 5000
# backend_secret_name = "backend-secret"
database_url = "postgresql://postgres:postgres@postgres:5432/kube"

#frontend
frontend_name     = "frontend"
frontend_image    = "tanishqjaiswal/infra-frontend:v9"
frontend_replicas = 1


