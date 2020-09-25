terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    null = {
      source = "hashicorp/null"
    }
    postgresql = {
      source = "terraform-providers/postgresql"
    }
    random = {
      source = "hashicorp/random"
    }
    tls = {
      source = "hashicorp/tls"
    }
    kubernetes-alpha = {
      source = "hashicorp/kubernetes-alpha"
    }
  }
  required_version = ">= 0.13"
}
