resource "kubernetes_namespace" "api-gateway" {
  metadata {
    name = "api-gateway"
  }
}

###################################
### Deploy the API gateway pods ###
###################################
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
            container_port = 8080
          }
        }
      }
    }
  }
}

#######################################################################
### Create Traefik ingress for the direct access to the API gateway ###
#######################################################################
resource "kubernetes_service" "api-gateway" {
  metadata {
    name      = "api-gateway"
    namespace = "api-gateway"
  }

  spec {
    selector = {
      app = "traefik"
    }
    session_affinity = "ClientIP"
    port {
      port        = 80
      target_port = 8080
    }
  }
}
resource "kubernetes_ingress" "api-gateway" {
  metadata {
    name      = "api-gateway"
    namespace = "api-gateway"
    annotations = {
      "kubernetes.io/ingress.class" = "traefik"

      "traefik.ingress.kubernetes.io/router.entrypoints"        = "web-secure"
      "traefik.ingress.kubernetes.io/router.tls.certresolver"   = "main"
      "traefik.ingress.kubernetes.io/router.tls.domains.0.main" = "api-gateway.${var.services_domain}"

      # TODO configure SANs for TLS
      # "traefik.ingress.kubernetes.io/router.tls.domains.0.sans" = "dashboard.${san}"
    }
  }

  spec {
    rule {
      host = "api-gateway.${var.services_domain}"
      http {
        path {
          path = "/"
          backend {
            service_name = kubernetes_service.api-gateway.metadata.0.name
            service_port = 80
          }
        }
      }
    }
  }
}
