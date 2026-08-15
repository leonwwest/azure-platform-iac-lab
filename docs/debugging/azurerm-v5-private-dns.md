# Debugging story: AzureRM v5 private DNS link migration

## Symptom

Provider validation failed after the AzureRM v5 upgrade because the private DNS virtual-network
link still used the removed resource-group and zone-name arguments.

## Diagnosis and fix

The v5 resource contract requires `private_dns_zone_id`. The link now references
`azurerm_private_dns_zone.key_vault.id`, and the repository contract test prevents the removed
arguments from returning.

## Prevention

Provider upgrades run Terraform validation, native policy tests and the static regression suite in
one pull request before merge.
