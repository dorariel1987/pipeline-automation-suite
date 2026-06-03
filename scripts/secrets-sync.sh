#!/usr/bin/env bash
# Pull a set of secrets from Azure Key Vault (or HashiCorp Vault) and
# project them into a Kubernetes Secret resource. Designed to run inside CI
# so values never appear in logs.
#
# Required env:
#   SECRET_NAME       Name of the Kubernetes Secret to create/update
#   K8S_NAMESPACE     Namespace for the Secret
#   SECRETS_MANIFEST  Path to a manifest of "k8s_key=vault_ref" lines
#
# Optional env:
#   VAULT_BACKEND     "azure" (default) or "hcv"
#   AZURE_KEYVAULT    Required if VAULT_BACKEND=azure
#   HCV_MOUNT         Required if VAULT_BACKEND=hcv (KV-v2 mount, e.g. "kv")
#   HCV_PATH          Required if VAULT_BACKEND=hcv (path inside the mount)
#
# SECRETS_MANIFEST format (one entry per line):
#   DATABASE_URL=prod/api/database-url
#   API_KEY=prod/api/api-key
# Lines starting with '#' and blank lines are ignored.

set -o errexit
set -o nounset
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib/logging.sh
source "${SCRIPT_DIR}/lib/logging.sh"
# shellcheck source=./lib/vault-helpers.sh
source "${SCRIPT_DIR}/lib/vault-helpers.sh"

main() {
    require_env SECRET_NAME K8S_NAMESPACE SECRETS_MANIFEST
    require_cmd kubectl

    [[ -f "${SECRETS_MANIFEST}" ]] || \
        log::fatal "manifest not found: ${SECRETS_MANIFEST}"

    local backend="${VAULT_BACKEND:-azure}"
    log::info "syncing secret ${K8S_NAMESPACE}/${SECRET_NAME} from ${backend}"

    local kv_pairs=""
    local line key ref value
    while IFS= read -r line || [[ -n "${line}" ]]; do
        line="${line%%#*}"
        [[ -z "${line// /}" ]] && continue
        IFS='=' read -r key ref <<<"${line}"
        key="${key// /}"
        ref="${ref// /}"

        case "${backend}" in
            azure)
                require_env AZURE_KEYVAULT
                value="$(vault::azure_get "${AZURE_KEYVAULT}" "${ref##*/}")"
                ;;
            hcv)
                require_env HCV_MOUNT HCV_PATH
                value="$(vault::hcv_get "${HCV_MOUNT}" "${HCV_PATH}" "${ref}")"
                ;;
            *)
                log::fatal "unknown VAULT_BACKEND: ${backend}"
                ;;
        esac

        kv_pairs+="${key}=${value}"$'\n'
        log::debug "resolved ${key} (length=${#value})"
    done < "${SECRETS_MANIFEST}"

    printf '%s' "${kv_pairs}" | vault::apply_secret "${SECRET_NAME}" "${K8S_NAMESPACE}"
    log::ok "secret sync complete"
}

main "$@"
