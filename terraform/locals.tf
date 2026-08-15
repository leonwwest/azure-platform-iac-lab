locals {
  suffix = "${var.project_name}-${var.environment}"

  tags = merge(var.governance_tags, {
    environment = var.environment
    managed-by  = "terraform"
    project     = "azure-platform-iac-lab"
  })
}
