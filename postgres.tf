resource "kubernetes_namespace" "postgres" {
  metadata {
    name = "postgres"
  }
}

############################################################
### Prepare Postgres server certificate and config files ###
############################################################
resource "random_password" "postgres_root_password" {
  length = 64
}
resource "tls_private_key" "postgres" {
  algorithm = "RSA"
}
resource "tls_self_signed_cert" "postgres" {
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.postgres.private_key_pem

  validity_period_hours = 8760

  subject {
    organization = "SMARTA Transit"
  }

  # TODO:
  # dns_names = ["db.${var.services_domain}"]

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}
resource "kubernetes_config_map" "postgres" {
  metadata {
    name      = "postgres"
    namespace = "postgres"
  }

  data = {
    "passfile"        = random_password.postgres_root_password.result
    "server.crt"      = tls_self_signed_cert.postgres.cert_pem
    "server.key"      = tls_private_key.postgres.private_key_pem
    "postgresql.conf" = <<EOT
ssl = on
ssl_cert_file = '/var/run/config/server.crt'
ssl_key_file = '/var/run/config/server.key'
EOT
  }
}

####################################################
### Create a persistent volume for Postgres data ###
####################################################
resource "kubernetes_persistent_volume_claim" "postgres" {
  metadata {
    name      = "postgres"
    namespace = "postgres"
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

#########################################
### Deploy the postgres server itself ###
#########################################
resource "kubernetes_deployment" "postgres" {
  metadata {
    name      = "postgres"
    namespace = "postgres"
    labels = {
      app = "postgres"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "postgres"
      }
    }

    template {
      metadata {
        name      = "postgres"
        namespace = "postgres"
        labels = {
          app = "postgres"
        }
      }

      spec {
        container {
          image = "postgres:12.3"
          name  = "postgres"

          args = [
            "-c", "hba_file=/var/run/config/pg_hba.conf",
            "-c", "config_file=/var/run/config/postgresql.conf",
          ]

          port {
            container_port = 5432
          }

          env {
            name  = "POSTGRES_PASSWORD_FILE"
            value = "/var/run/config/passfile"
          }
          env {
            name  = "PGDATA"
            value = "/var/lib/postgresql/data/pgdata"
          }

          volume_mount {
            mount_path = "/var/lib/postgresql/data"
            name       = "postgres-data"
          }
          volume_mount {
            mount_path = "/var/run/config/passfile"
            name       = "postgres-config"
          }
        }

        volume {
          name = "postgres-data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.postgres.metadata.0.name
          }
        }
        volume {
          name = "postgres-config"
          config_map {
            name = kubernetes_config_map.postgres.metadata.0.name
          }
        }
      }
    }
  }
}

##################################
### Expose the postgres server ###
##################################
resource "kubernetes_service" "postgres" {
  metadata {
    name      = "postgres"
    namespace = "postgres"
  }

  spec {
    selector = {
      app = "postgres"
    }
    session_affinity = "ClientIP"
    port {
      protocol    = "TCP"
      port        = 5432
      target_port = 5432
    }
  }
}
