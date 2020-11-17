provider "kubernetes" {
  load_config_file       = false
  cluster_ca_certificate = base64decode(var.kube_ca_certificate)
  host                   = "https://${var.kube_host}"
  token                  = var.kube_token
}
provider "kubernetes-alpha" {
  cluster_ca_certificate = base64decode(var.kube_ca_certificate)
  host                   = "https://${var.kube_host}"
  token                  = var.kube_token
}

terraform {
  backend "remote" {
    organization = "smartatransit"

    workspaces {
      name = "kube-system"
    }
  }
}
