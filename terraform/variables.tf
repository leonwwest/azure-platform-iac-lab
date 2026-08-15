variable "subscription_id" {
  description = "Azure subscription ID. Supply through ARM_SUBSCRIPTION_ID in CI."
  type        = string
  sensitive   = true
  default     = "00000000-0000-0000-0000-000000000000"

  validation {
    condition     = can(regex("^[0-9a-fA-F-]{36}$", var.subscription_id))
    error_message = "subscription_id must be a GUID."
  }
}

variable "location" {
  description = "Primary Azure region."
  type        = string
  default     = "germanywestcentral"

  validation {
    condition     = contains(["germanywestcentral", "westeurope"], var.location)
    error_message = "location must be an approved EU region: germanywestcentral or westeurope."
  }
}

variable "environment" {
  description = "Short environment name used in tags and resource names."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "environment must be dev, test or prod."
  }
}

variable "project_name" {
  description = "DNS-safe project identifier."
  type        = string
  default     = "platformlab"

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{2,15}$", var.project_name))
    error_message = "project_name must contain 3-16 lowercase alphanumeric characters and start with a letter."
  }
}

variable "container_image" {
  description = "Public demonstration image. Production should use a digest-pinned private image."
  type        = string
  default     = "mcr.microsoft.com/k8se/quickstart:latest"
}

variable "alert_email" {
  description = "Optional operations email. Empty disables the action group and metric alert."
  type        = string
  default     = ""

  validation {
    condition     = var.alert_email == "" || can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.alert_email))
    error_message = "alert_email must be empty or a valid email address."
  }
}

variable "budget_contact_emails" {
  description = "Optional recipients. Empty disables the resource-group budget."
  type        = list(string)
  default     = []
}

variable "monthly_budget_eur" {
  description = "Monthly budget amount when budget_contact_emails is non-empty."
  type        = number
  default     = 25

  validation {
    condition     = var.monthly_budget_eur >= 5 && var.monthly_budget_eur <= 100
    error_message = "monthly_budget_eur must be between 5 and the lab guardrail of 100 EUR."
  }
}

variable "max_replicas" {
  description = "Maximum Container App replicas; capped for predictable portfolio-lab cost."
  type        = number
  default     = 1

  validation {
    condition     = var.max_replicas >= 1 && var.max_replicas <= 3
    error_message = "max_replicas must be between 1 and the lab guardrail of 3."
  }
}

variable "governance_tags" {
  description = "Required ownership and cost-allocation tags applied to taggable resources."
  type        = map(string)
  default = {
    owner       = "leon-westermeir"
    cost-center = "portfolio"
    purpose     = "portfolio-lab"
  }

  validation {
    condition = alltrue([
      for key in ["owner", "cost-center", "purpose"] :
      contains(keys(var.governance_tags), key) && trimspace(lookup(var.governance_tags, key, "")) != ""
    ])
    error_message = "governance_tags must contain non-empty owner, cost-center and purpose values."
  }
}
