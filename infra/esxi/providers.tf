# The password is read by the provider from the environment variable `esxi_password`
# (provider default), so it never becomes a Terraform variable and never lands in a saved plan.
# scripts/tf.sh loads it from $ESXI_PASSWORD_FILE on the runner.
provider "esxi" {
  esxi_hostname = var.esxi_hostname
  esxi_hostport = "22"
  esxi_hostssl  = "443"
  esxi_username = var.esxi_username
}
