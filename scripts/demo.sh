#!/usr/bin/env bash
set -euo pipefail

resource_group="${1:-rg-platformlab-dev}"
output="docs/evidence/latest.md"
mkdir -p "$(dirname "${output}")"

command -v az >/dev/null || { echo "Azure CLI is required." >&2; exit 1; }
az account show >/dev/null

app_name="$(az containerapp list -g "${resource_group}" --query '[0].name' -o tsv)"
[[ -n "${app_name}" ]] || { echo "No Container App found in ${resource_group}." >&2; exit 1; }

fqdn="$(az containerapp show -g "${resource_group}" -n "${app_name}" --query properties.configuration.ingress.fqdn -o tsv)"
min_replicas="$(az containerapp show -g "${resource_group}" -n "${app_name}" --query properties.template.scale.minReplicas -o tsv)"
max_replicas="$(az containerapp show -g "${resource_group}" -n "${app_name}" --query properties.template.scale.maxReplicas -o tsv)"
identity_type="$(az containerapp show -g "${resource_group}" -n "${app_name}" --query identity.type -o tsv)"

generated_at="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
content=$(printf '# Deployment evidence\n\nGenerated from read-only Azure CLI queries at `%s`.\n\n| Check | Observed value |\n|---|---|\n| Resource group | `%s` |\n| Container App | `%s` |\n| HTTPS endpoint | `https://%s` |\n| Replica range | `%s..%s` |\n| Identity | `%s` |\n' "${generated_at}" "${resource_group}" "${app_name}" "${fqdn}" "${min_replicas}" "${max_replicas}" "${identity_type}")

python3 - "${output}" "${content}" <<'PY'
from pathlib import Path
import sys
Path(sys.argv[1]).write_text(sys.argv[2], encoding="utf-8")
PY

echo "Wrote ${output}"
