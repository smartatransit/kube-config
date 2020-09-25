provider "kubernetes" {}
provider "kubernetes-alpha" {
  # TODO
  # config_path = "~/.kube/config"
}

terraform {
  backend "kubernetes" {
    secret_suffix     = "kube-system"
    in_cluster_config = true
  }
}
