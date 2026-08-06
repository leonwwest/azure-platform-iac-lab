locals {
  suffix = "${var.project_name}-${var.environment}"

  tags = {
    environment = var.environment
    managed-by  = "terraform"
    owner       = "leon-westermeir"
    project     = "azure-platform-iac-lab"
    purpose     = "portfolio-lab"
  }
}
