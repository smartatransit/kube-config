variable "services_domain" {
  type        = string
  description = "The domain under which to serve services on subdomains"
  default     = "services.smartatransit.com"
}
variable "postgres_hostname" {
  type    = string
  default = "postgres.postgres.svc.cluster.local"
}
variable "lets_encrypt_email" {
  type = string
}
variable "drone_github_client_id" {
  type = string
}
variable "drone_github_client_secret" {
  type = string
}
variable "drone_initial_admin_github_username" {
  type = string
}
variable "kubernetes_service_host" {
  type = string
}
variable "kubernetes_service_port" {
  type = string
}
variable "auth0_tenant_url" {
  type = string
}
variable "auth0_client_audience" {
  type = string
}
variable "auth0_anonymous_client_id" {
  type = string
}
variable "auth0_anonymous_client_secret" {
  type = string
}
variable "github_org" {
  type = string
}
variable "logzio_token" {
  type = string
}
variable "logzio_url" {
  type = string
}
