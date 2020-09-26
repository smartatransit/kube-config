output "admin_auth_password" {
  value = random_password.admin_basic_auth.result
}
output "postgres_root_password" {
  value = random_password.postgres_root_password.result
}
