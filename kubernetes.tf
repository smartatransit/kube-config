provider "kubernetes" {}
provider "kubernetes-alpha" {
  config_path = "~/.kube/config"
}

terraform {
  backend "kubernetes" {
    secret_suffix = "kube-system"
  }
}
