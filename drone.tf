resource "kubernetes_namespace" "drone" {
  metadata {
    name = "drone"
  }
}

resource "kubernetes_cluster_role" "drone" {
  metadata {
    name = "drone"
  }

  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["create", "delete"]
  }
  rule {
    api_groups = [""]
    resources  = ["pods", "pods/log"]
    verbs      = ["get", "create", "delete", "list", "watch", "update"]
  }
}
resource "kubernetes_service_account" "drone" {
  metadata {
    name      = "drone"
    namespace = "drone"
  }
}
resource "kubernetes_cluster_role_binding" "drone" {
  metadata {
    name = "drone"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.drone.metadata.0.name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.drone.metadata.0.name
    namespace = "drone"
  }
}

resource "kubernetes_persistent_volume_claim" "drone" {
  metadata {
    name      = "drone"
    namespace = "drone"
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "10Gi"
      }
    }
  }
}

resource "random_password" "drone_rpc_secret" {
  length = 128
}
resource "kubernetes_deployment" "drone-server" {
  metadata {
    name      = "drone-server"
    namespace = "drone"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "drone-server"
      }
    }

    template {
      metadata {
        namespace = "drone"
        labels    = { app = "drone-server" }
      }

      spec {
        service_account_name            = kubernetes_service_account.drone.metadata.0.name
        automount_service_account_token = true

        container {
          image = "drone/drone:1.9.0"
          name  = "drone"

          env {
            name  = "DRONE_AGENTS_ENABLED"
            value = "true"
          }
          env {
            name  = "DRONE_GITHUB_SERVER"
            value = "https://github.com"
          }
          env {
            name  = "DRONE_GITHUB_CLIENT_ID"
            value = var.drone_github_client_id
          }
          env {
            name  = "DRONE_GITHUB_CLIENT_SECRET"
            value = var.drone_github_client_secret
          }
          env {
            name  = "DRONE_RPC_SECRET"
            value = random_password.drone_rpc_secret.result
          }
          env {
            name  = "DRONE_SERVER_HOST"
            value = "infra.${var.services_domain}"
          }
          env {
            name  = "DRONE_SERVER_PROTO"
            value = "https"
          }
          env {
            name  = "DRONE_USER_CREATE"
            value = "username:${var.drone_initial_admin_github_username},admin:true"
          }

          # TODO: 
          # DRONE_LOGS_DEBUG = true

          port {
            name           = "web"
            container_port = 80
          }

          volume_mount {
            mount_path = "/data"
            name       = "data"
          }
        }

        volume {
          name = "data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.drone.metadata.0.name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "drone" {
  metadata {
    name      = "drone"
    namespace = "drone"
  }

  spec {
    selector = {
      app = "drone-server"
    }
    session_affinity = "ClientIP"
    port {
      port        = 80
      target_port = 80
    }
  }
}
resource "kubernetes_ingress" "drone" {
  metadata {
    name      = "drone"
    namespace = "drone"
    annotations = {
      "kubernetes.io/ingress.class" = "traefik"

      "traefik.ingress.kubernetes.io/router.entrypoints"        = "web-secure"
      "traefik.ingress.kubernetes.io/router.tls.certresolver"   = "main"
      "traefik.ingress.kubernetes.io/router.tls.domains.0.main" = "infra.${var.services_domain}"

      # TODO configure SANs for TLS
      # "traefik.ingress.kubernetes.io/router.tls.domains.0.sans" = "dashboard.${san}"
    }
  }

  spec {
    rule {
      host = "infra.${var.services_domain}"
      http {
        path {
          path = "/"
          backend {
            service_name = kubernetes_service.drone.metadata.0.name
            service_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_service_account" "terraform" {
  metadata {
    name      = "terraform"
    namespace = "drone"
  }
}
resource "kubernetes_cluster_role_binding" "terraform" {
  metadata {
    name      = "terraform"
    namespace = "drone"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "terraform"
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.terraform.metadata.0.name
    namespace = "drone"
  }
}

resource "kubernetes_deployment" "drone-runner" {
  metadata {
    name      = "drone-runner"
    namespace = "drone"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "drone-runner"
      }
    }

    template {
      metadata {
        namespace = "drone"
        labels    = { app = "drone-runner" }
      }

      spec {
        service_account_name            = kubernetes_service_account.drone.metadata.0.name
        automount_service_account_token = true

        container {
          image = "drone/drone-runner-kube:latest"
          name  = "drone"

          env {
            name  = "DRONE_RPC_HOST"
            value = "drone.drone.svc.cluster.local"
          }

          env {
            name  = "DRONE_RPC_PROTO"
            value = "http"
          }
          env {
            name  = "DRONE_RPC_SECRET"
            value = random_password.drone_rpc_secret.result
          }
          env {
            name  = "DRONE_NAMESPACE_DEFAULT"
            value = "drone"
          }
          env {
            name  = "DRONE_SERVICE_ACCOUNT_DEFAULT"
            value = kubernetes_service_account.terraform.metadata.0.name
          }

          port {
            container_port = 3000
          }
        }
      }
    }
  }
}
