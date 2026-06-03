#!/usr/bin/env bash
# Automated rollback to a previous Deployment revision.
#
# Two modes are supported:
#   1. SNAPSHOT_PATH=/tmp/.../deployment.yaml  → restore from a captured snapshot
#   2. Default                                  → kubectl rollout undo to N-1
#
# Required env:
#   SERVICE_NAME    Deployment name
#   K8S_NAMESPACE   Target namespace
#
# Optional env:
#   SNAPSHOT_PATH       Directory created by k8s::snapshot
#   ROLLOUT_TIMEOUT     Seconds to wait (default: 300)
#   HEALTH_PATH         HTTP path to verify after rollback (default: /healthz)
#   POST_HOOK           Path to an executable run on success (notifications etc.)

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

    local rollout_timeout="${ROLLOUT_TIMEOUT:-300}"
    local health_path="${HEALTH_PATH:-/healthz}"

    log::warn "=== rollback initiated: ${K8S_NAMESPACE}/${SERVICE_NAME} ==="

    if [[ -n "${SNAPSHOT_PATH:-}" ]] && [[ -f "${SNAPSHOT_PATH}/deployment.yaml" ]]; then
        log::info "restoring from snapshot ${SNAPSHOT_PATH}"
        kubectl apply -f "${SNAPSHOT_PATH}/deployment.yaml"
    else
        local prev
        prev="$(k8s::previous_revision "${K8S_NAMESPACE}" "${SERVICE_NAME}" || true)"
        if [[ -z "${prev}" ]]; then
            log::fatal "no previous revision available to roll back to"
        fi
        log::info "rolling back ${SERVICE_NAME} to revision ${prev}"
        kubectl --namespace "${K8S_NAMESPACE}" rollout undo \
            "deployment/${SERVICE_NAME}" --to-revision="${prev}"
    fi

    k8s::wait_rollout "${K8S_NAMESPACE}" "${SERVICE_NAME}" "${rollout_timeout}"

    if ! k8s::probe_service "${K8S_NAMESPACE}" "${SERVICE_NAME}" "${health_path}"; then
        log::fatal "rollback restored a revision but health probe still failing — manual intervention required"
    fi

    log::ok "=== rollback complete and verified: ${K8S_NAMESPACE}/${SERVICE_NAME} ==="

    if [[ -n "${POST_HOOK:-}" ]] && [[ -x "${POST_HOOK}" ]]; then
        log::info "running post-rollback hook: ${POST_HOOK}"
        "${POST_HOOK}" "${SERVICE_NAME}" "${K8S_NAMESPACE}"
    fi
}

main "$@"
