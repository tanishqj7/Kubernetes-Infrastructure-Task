resource "kubernetes_service_account" "backend_sa" {
  metadata {
    name      = "flask-backend-sa"
    namespace = var.namespace
  }
}

# ClusterRole
resource "kubernetes_cluster_role" "backend_role" {
  metadata {
    name = "flask-backend-clusterrole"
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "services", "endpoints", "namespaces"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = [""]
    resources  = ["pods/log"]
    verbs      = ["get", "list"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "replicasets"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = ["batch"]
    resources  = ["jobs"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }
}

# ClusterRoleBinding
resource "kubernetes_cluster_role_binding" "backend_binding" {
  metadata {
    name = "flask-backend-clusterrolebinding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.backend_role.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.backend_sa.metadata[0].name
    namespace = var.namespace
  }
}
