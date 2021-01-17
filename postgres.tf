resource "kubernetes_namespace" "postgres" {
  metadata {
    name = "postgres"
  }
}

##################################
### Generate the root password ###
##################################
resource "random_password" "postgres_root_password" {
  length = 64
}
resource "kubernetes_config_map" "postgres" {
  metadata {
    name      = "postgres"
    namespace = kubernetes_namespace.postgres.metadata.0.name
  }

  data = {
    "passfile" = random_password.postgres_root_password.result
  }
}

####################################################
### Create a persistent volume for Postgres data ###
####################################################
resource "kubernetes_persistent_volume_claim" "postgres" {
  metadata {
    name      = "postgres"
    namespace = kubernetes_namespace.postgres.metadata.0.name
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "50Gi"
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
    namespace = kubernetes_namespace.postgres.metadata.0.name
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
        labels = {
          app = "postgres"
        }
      }

      spec {
        container {
          image = "postgres:12.5"
          name  = "postgres"

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
            sub_path   = "passfile"
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
    namespace = kubernetes_namespace.postgres.metadata.0.name
  }

  spec {
    selector = {
      app = "postgres"
    }
    session_affinity = "ClientIP"
    port {
      port = 5432
    }
  }
}
