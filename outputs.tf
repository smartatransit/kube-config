output "admin_auth_password" {
  value = random_password.admin_basic_auth.result
}
