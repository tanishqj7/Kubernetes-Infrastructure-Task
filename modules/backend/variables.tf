variable "namespace" {
  type = string
}

variable "backend_name" {
  type = string
}
variable "backend_replicas" {
  type = number
}

variable "backend_image" {
  type = string
}

variable "flask_port" {
  type = number
}

variable "app_config_name" {
  type = string
}