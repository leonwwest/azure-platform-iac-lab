# Architecture decisions

## ADR-001: Azure Container Apps instead of AKS

**Status:** Accepted

The portfolio lab focuses on platform automation, identity and safe delivery. AKS would add recurring cost and cluster maintenance that do not strengthen those learning goals. Container Apps retains container scheduling, revisions, ingress, autoscaling and managed identity while allowing scale-to-zero.

## ADR-002: OIDC instead of client secrets

**Status:** Accepted

GitHub Actions obtains short-lived tokens from Microsoft Entra workload identity federation. The repository stores identifiers as environment variables but no reusable authentication secret. Plan and apply use separate identities and GitHub environments.

## ADR-003: Empty Key Vault instead of Terraform-managed demo secrets

**Status:** Accepted

Terraform state would contain the plaintext value of any `azurerm_key_vault_secret` resource. The lab therefore creates the vault, workload identity and RBAC relationship without provisioning a fake secret. Operational secret insertion belongs in a separate controlled process.

## ADR-004: Remote state with Azure Blob

**Status:** Accepted

Azure Blob provides state locking and supports Microsoft Entra authentication with OIDC. Backend coordinates are supplied at workflow runtime so no subscription-specific values are committed.

## ADR-005: Private Key Vault access

**Status:** Accepted

The vault disables public network access. A dedicated private endpoint and Private DNS zone make the service reachable from the workload VNet without relying on public firewall exceptions. Container Apps and private endpoints use separate subnets so delegation and endpoint policies remain explicit.
