resource "kubernetes_namespace" "api-gateway" {
  metadata {
    name = "api-gateway"
  }
}

resource "kubernetes_deployment" "api-gateway" {
  metadata {
    name      = "api-gateway"
    namespace = "api-gateway"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "api-gateway"
      }
    }

    template {
      metadata {
        labels = { app = "api-gateway" }
      }

      spec {
        service_account_name            = "api-gateway"
        automount_service_account_token = true

        container {
          image = "smartatransit/api-gateway:build-30"
          name  = "api-gateway"

          env {
            name  = "AUTH0_TENANT_URL"
            value = var.auth0_tenant_url
          }
          env {
            name  = "AUTH0_CLIENT_AUDIENCE"
            value = var.auth0_client_audience
          }
          env {
            name  = "CLIENT_ID"
            value = var.auth0_anonymous_client_id
          }
          env {
            name  = "CLIENT_SECRET"
            value = var.auth0_anonymous_client_secret
          }

          port {
            name           = "web"
            container_port = 80
          }
        }
      }
    }
  }
}
