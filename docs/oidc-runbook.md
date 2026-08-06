# OIDC and deployment runbook

## Required GitHub environments

Create two environments:

- `plan`: read-only Azure identity, no deployment approval required.
- `production`: apply identity, at least one required reviewer and no self-bypass.

## Non-secret environment variables

Configure these variables in both environments:

- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`
- `TFSTATE_RESOURCE_GROUP`
- `TFSTATE_STORAGE_ACCOUNT`
- `TFSTATE_CONTAINER`

Identifiers are not credentials, but environment scoping makes their ownership explicit. Never add a client secret.

## Federated subjects

The bootstrap helper creates credentials with these exact subjects:

```text
repo:leonwwest/azure-platform-iac-lab:environment:plan
repo:leonwwest/azure-platform-iac-lab:environment:production
```

## Minimum access model

1. Give the plan identity `Reader` on the target resource group and `Storage Blob Data Contributor` only on the state container.
2. Give the production identity the narrowest custom deployment role practical for the target resource group plus state access.
3. Keep subscription-level `Owner` and `User Access Administrator` out of routine workflows.
4. Review role assignments after every platform expansion.

## State bootstrap

Create the backend once with Azure CLI or a separate bootstrap stack. Enable blob versioning and soft delete. The workflows pass backend coordinates through `terraform init -backend-config` and authenticate using OIDC.

## Recovery

- A failed plan does not change Azure.
- A failed apply is followed by a fresh plan; never rerun blindly.
- Restore an earlier state blob version only after comparing Azure resources and current state.
- Remove a compromised federated credential immediately; no client secret rotation is necessary.
