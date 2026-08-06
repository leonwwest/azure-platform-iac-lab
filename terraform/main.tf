resource "azurerm_resource_group" "platform" {
  name     = "rg-${local.suffix}"
  location = var.location
  tags     = local.tags
}

resource "azurerm_log_analytics_workspace" "platform" {
  name                = "law-${local.suffix}"
  location            = azurerm_resource_group.platform.location
  resource_group_name = azurerm_resource_group.platform.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  daily_quota_gb      = 0.5
  tags                = local.tags
}

resource "azurerm_virtual_network" "platform" {
  name                = "vnet-${local.suffix}"
  location            = azurerm_resource_group.platform.location
  resource_group_name = azurerm_resource_group.platform.name
  address_space       = ["10.42.0.0/16"]
  tags                = local.tags
}

resource "azurerm_subnet" "container_apps" {
  name                 = "snet-container-apps"
  resource_group_name  = azurerm_resource_group.platform.name
  virtual_network_name = azurerm_virtual_network.platform.name
  address_prefixes     = ["10.42.0.0/23"]

  delegation {
    name = "container-apps"

    service_delegation {
      name    = "Microsoft.App/environments"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_subnet" "private_endpoints" {
  name                              = "snet-private-endpoints"
  resource_group_name               = azurerm_resource_group.platform.name
  virtual_network_name              = azurerm_virtual_network.platform.name
  address_prefixes                  = ["10.42.2.0/24"]
  private_endpoint_network_policies = "Disabled"
}

resource "azurerm_network_security_group" "container_apps" {
  name                = "nsg-${local.suffix}-container-apps"
  location            = azurerm_resource_group.platform.location
  resource_group_name = azurerm_resource_group.platform.name
  tags                = local.tags
}

resource "azurerm_network_security_group" "private_endpoints" {
  name                = "nsg-${local.suffix}-private-endpoints"
  location            = azurerm_resource_group.platform.location
  resource_group_name = azurerm_resource_group.platform.name
  tags                = local.tags
}

resource "azurerm_subnet_network_security_group_association" "container_apps" {
  subnet_id                 = azurerm_subnet.container_apps.id
  network_security_group_id = azurerm_network_security_group.container_apps.id
}

resource "azurerm_subnet_network_security_group_association" "private_endpoints" {
  subnet_id                 = azurerm_subnet.private_endpoints.id
  network_security_group_id = azurerm_network_security_group.private_endpoints.id
}

resource "azurerm_user_assigned_identity" "workload" {
  name                = "id-${local.suffix}"
  location            = azurerm_resource_group.platform.location
  resource_group_name = azurerm_resource_group.platform.name
  tags                = local.tags
}

resource "azurerm_key_vault" "platform" {
  name                          = "kv-${var.project_name}-${var.environment}"
  location                      = azurerm_resource_group.platform.location
  resource_group_name           = azurerm_resource_group.platform.name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = "standard"
  rbac_authorization_enabled    = true
  purge_protection_enabled      = var.environment == "prod"
  soft_delete_retention_days    = 7
  public_network_access_enabled = false
  tags                          = local.tags

  network_acls {
    bypass         = "AzureServices"
    default_action = "Deny"
  }
}

resource "azurerm_private_dns_zone" "key_vault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.platform.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "key_vault" {
  name                  = "link-${local.suffix}-key-vault"
  resource_group_name   = azurerm_resource_group.platform.name
  private_dns_zone_name = azurerm_private_dns_zone.key_vault.name
  virtual_network_id    = azurerm_virtual_network.platform.id
  registration_enabled  = false
  tags                  = local.tags
}

resource "azurerm_private_endpoint" "key_vault" {
  name                = "pe-${local.suffix}-key-vault"
  location            = azurerm_resource_group.platform.location
  resource_group_name = azurerm_resource_group.platform.name
  subnet_id           = azurerm_subnet.private_endpoints.id
  tags                = local.tags

  private_service_connection {
    name                           = "psc-${local.suffix}-key-vault"
    private_connection_resource_id = azurerm_key_vault.platform.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.key_vault.id]
  }
}

resource "azurerm_role_assignment" "workload_key_vault_secrets" {
  scope                = azurerm_key_vault.platform.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.workload.principal_id
}

resource "azurerm_container_app_environment" "platform" {
  name                       = "cae-${local.suffix}"
  location                   = azurerm_resource_group.platform.location
  resource_group_name        = azurerm_resource_group.platform.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.platform.id
  infrastructure_subnet_id   = azurerm_subnet.container_apps.id
  tags                       = local.tags
}

resource "azurerm_container_app" "demo" {
  name                         = "ca-${local.suffix}"
  container_app_environment_id = azurerm_container_app_environment.platform.id
  resource_group_name          = azurerm_resource_group.platform.name
  revision_mode                = "Single"
  tags                         = local.tags

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.workload.id]
  }

  ingress {
    allow_insecure_connections = false
    external_enabled           = true
    target_port                = 80

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  template {
    min_replicas = 0
    max_replicas = 1

    container {
      name   = "demo"
      image  = var.container_image
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name  = "APP_ENV"
        value = var.environment
      }

      liveness_probe {
        transport = "HTTP"
        port      = 80
        path      = "/"
      }

      readiness_probe {
        transport = "HTTP"
        port      = 80
        path      = "/"
      }
    }
  }

  lifecycle {
    precondition {
      condition     = var.environment != "prod" || !endswith(var.container_image, ":latest")
      error_message = "Production deployments must use a digest or immutable image tag."
    }
  }
}
