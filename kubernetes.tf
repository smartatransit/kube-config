provider "kubernetes" {
  config_context = "smarta-developer"
}

terraform {
  backend "kubernetes" {
    secret_suffix = "kube-system"
  }
}
