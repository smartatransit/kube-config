provider "kubernetes" {}
provider "kubernetes-alpha" {}

terraform {
  backend "kubernetes" {
    secret_suffix     = "kube-system"
    in_cluster_config = true
  }
}
