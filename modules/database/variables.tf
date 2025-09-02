variable "postgres_name" {
  type = string
}

variable "namespace" {
  type = string
}

variable "postgres_image" {
  type = string
}

variable "postgres_replicas" {
  type = number
}

variable "db_name" {
  type = string
}

variable "db_user" {
  type = string
}

variable "db_password" {
  type = string
  sensitive   = true

}

variable "pgdata" {
  type = string
}

variable "storage_class" {
  type = string
}

variable "storage_size" {
  type = string
}