#!/usr/bin/env bash
# Stand-alone health probe used as a quality gate by both CI systems.
#
# Required env:
#   SERVICE_NAME    Service to probe
#   K8S_NAMESPACE   Namespace where Service lives
#
# Optional env:
#   HEALTH_PATH     HTTP path (default: /healthz)
#   EXPECTED_STATUS Expected HTTP status (default: 200)
#   RETRIES         How many attempts (default: 10)
#   SLEEP_SECS      Backoff between attempts (default: 6)

set -o errexit
set -o nounset
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib/logging.sh
source "${SCRIPT_DIR}/lib/logging.sh"
# shellcheck source=./lib/kubectl-helpers.sh
source "${SCRIPT_DIR}/lib/kubectl-helpers.sh"

main() {
    require_env SERVICE_NAME K8S_NAMESPACE
    require_cmd kubectl

    local path="${HEALTH_PATH:-/healthz}"
    local expected="${EXPECTED_STATUS:-200}"
    local retries="${RETRIES:-10}"
    local sleep_secs="${SLEEP_SECS:-6}"

    local attempt=1
    while (( attempt <= retries )); do
        log::info "health-check attempt ${attempt}/${retries}: ${SERVICE_NAME}${path}"
        if k8s::probe_service "${K8S_NAMESPACE}" "${SERVICE_NAME}" "${path}" "${expected}"; then
            log::ok "service ${SERVICE_NAME} is healthy"
            exit 0
        fi
        sleep "${sleep_secs}"
        ((attempt++))
    done

    log::fatal "service ${SERVICE_NAME} failed health-check after ${retries} attempts"
}

main "$@"
