#!/usr/bin/env bash
set -euo pipefail

required=(AZURE_SUBSCRIPTION_ID GITHUB_OWNER GITHUB_REPOSITORY)
for name in "${required[@]}"; do
  if [[ -z "${!name:-}" ]]; then
    echo "Missing required environment variable: ${name}" >&2
    exit 1
  fi
done

command -v az >/dev/null || { echo "Azure CLI is required." >&2; exit 1; }

location="${AZURE_LOCATION:-germanywestcentral}"
bootstrap_group="${AZURE_BOOTSTRAP_RESOURCE_GROUP:-rg-platformlab-identity}"

az account set --subscription "${AZURE_SUBSCRIPTION_ID}"
tenant_id="$(az account show --query tenantId -o tsv)"

az group create --name "${bootstrap_group}" --location "${location}" --tags purpose=portfolio-lab managed-by=bootstrap >/dev/null

create_identity() {
  local purpose="$1"
  local identity="id-platformlab-${purpose}"
  az identity create --resource-group "${bootstrap_group}" --name "${identity}" --location "${location}" >/dev/null
  local client_id principal_id identity_id
  client_id="$(az identity show -g "${bootstrap_group}" -n "${identity}" --query clientId -o tsv)"
  principal_id="$(az identity show -g "${bootstrap_group}" -n "${identity}" --query principalId -o tsv)"
  identity_id="$(az identity show -g "${bootstrap_group}" -n "${identity}" --query id -o tsv)"

  local subject="repo:${GITHUB_OWNER}/${GITHUB_REPOSITORY}:environment:${purpose}"
  if ! az identity federated-credential show --resource-group "${bootstrap_group}" --identity-name "${identity}" --name "github-${purpose}" >/dev/null 2>&1; then
    az identity federated-credential create \
      --resource-group "${bootstrap_group}" \
      --identity-name "${identity}" \
      --name "github-${purpose}" \
      --issuer "https://token.actions.githubusercontent.com" \
      --subject "${subject}" \
      --audiences "api://AzureADTokenExchange" >/dev/null
  fi

  printf '%s_CLIENT_ID=%s\n' "${purpose^^}" "${client_id}"
  printf '%s_PRINCIPAL_ID=%s\n' "${purpose^^}" "${principal_id}"
  printf '%s_IDENTITY_ID=%s\n' "${purpose^^}" "${identity_id}"
}

echo "# Configure these as GitHub environment variables"
echo "AZURE_TENANT_ID=${tenant_id}"
echo "AZURE_SUBSCRIPTION_ID=${AZURE_SUBSCRIPTION_ID}"
create_identity plan
create_identity production

cat <<'EOF'

No broad role assignment was created automatically.
Grant Reader to the plan identity and the narrowest required deployment role to
the production identity after reviewing docs/oidc-runbook.md.
EOF
