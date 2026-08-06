output "resource_group_name" {
  description = "Resource group containing the lab."
  value       = azurerm_resource_group.platform.name
}

output "container_app_fqdn" {
  description = "HTTPS endpoint of the demonstration service."
  value       = azurerm_container_app.demo.latest_revision_fqdn
}

output "managed_identity_client_id" {
  description = "Client ID used by the Container App workload."
  value       = azurerm_user_assigned_identity.workload.client_id
}

output "key_vault_uri" {
  description = "Key Vault endpoint. No secret values are output."
  value       = azurerm_key_vault.platform.vault_uri
}

output "log_analytics_workspace_id" {
  description = "Workspace resource ID for diagnostics and queries."
  value       = azurerm_log_analytics_workspace.platform.id
}
