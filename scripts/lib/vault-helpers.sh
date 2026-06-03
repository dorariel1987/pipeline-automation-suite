#!/usr/bin/env bash
# Helpers to read secrets from Azure Key Vault or HashiCorp Vault and project
# them as Kubernetes Secret manifests. Source after logging.sh.

# shellcheck source=./logging.sh
source "$(dirname "${BASH_SOURCE[0]}")/logging.sh"

# Fetch a single secret value from Azure Key Vault.
# Usage: vault::azure_get <vault_name> <secret_name>
vault::azure_get() {
    local vault="$1"
    local name="$2"

    require_cmd az
    az keyvault secret show \
        --vault-name "${vault}" \
        --name "${name}" \
        --query value -o tsv
}

# Fetch a key from a HashiCorp Vault KV-v2 path.
# Usage: vault::hcv_get <mount> <path> <key>
vault::hcv_get() {
    local mount="$1"
    local path="$2"
    local key="$3"

    require_cmd vault
    vault kv get -mount="${mount}" -field="${key}" "${path}"
}

# Render a generic-opaque Kubernetes Secret YAML from a list of "key=value"
# pairs read on stdin. Values are base64 encoded.
# Usage:  printf 'A=1\nB=2\n' | vault::render_secret my-secret default
vault::render_secret() {
    local name="$1"
    local namespace="$2"

    {
        printf 'apiVersion: v1\nkind: Secret\nmetadata:\n'
        printf '  name: %s\n  namespace: %s\ntype: Opaque\ndata:\n' \
            "${name}" "${namespace}"
        while IFS='=' read -r k v; do
            [[ -z "${k}" ]] && continue
            printf '  %s: %s\n' "${k}" "$(printf '%s' "${v}" | base64 -w0 2>/dev/null || printf '%s' "${v}" | base64)"
        done
    }
}

# Apply a Secret atomically: render → kubectl apply → cleanup.
# Usage: vault::apply_secret <name> <namespace> < env-style-stdin
vault::apply_secret() {
    local name="$1"
    local namespace="$2"
    local tmp
    tmp="$(mktemp)"
    trap 'rm -f "${tmp}"' RETURN

    vault::render_secret "${name}" "${namespace}" > "${tmp}"
    kubectl apply -f "${tmp}" >/dev/null
    log::ok "applied secret ${namespace}/${name}"
}
