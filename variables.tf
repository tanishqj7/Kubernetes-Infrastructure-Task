variable "namespace" { type = string}


variable "postgres_name" { type = string }
variable "postgres_image" { type = string }
variable "postgres_replicas" { type = number }
variable "db_name" { type = string }
variable "db_user" { type = string }
variable "db_password" { type = string }
variable "pgdata" { type = string }
variable "storage_class" { type = string }
variable "storage_size" { type = string }
variable "app_config_name" { type = string }


variable "backend_name" { type = string }
variable "backend_image" { type = string }
variable "backend_replicas" { type = number }
variable "flask_port" { type = number }


variable "frontend_name" { type = string }
variable "frontend_image" { type = string }
variable "frontend_replicas" { type = number }



