#!/usr/bin/env bash
# Deploy a containerised service to Kubernetes with snapshotting + health gate.
#
# This is the single deploy entry-point consumed by both Azure DevOps and
# Bitbucket pipelines. It is intentionally framework-agnostic — all inputs are
# environment variables so the CI templates stay declarative.
#
# Required env:
#   SERVICE_NAME      Logical service name (used as Deployment + label selector)
#   IMAGE             Fully-qualified image, e.g. myacr.azurecr.io/api:1.2.3
#   K8S_NAMESPACE     Target namespace
#   ENVIRONMENT       dev|staging|prod (controls health-gate strictness)
#
# Optional env:
#   CHART_PATH        Helm chart path (default: kubernetes/helm/app-chart)
#   VALUES_FILE       Extra values file passed to helm upgrade
#   ROLLOUT_TIMEOUT   Seconds to wait for rollout (default: 300)
#   HEALTH_PATH       HTTP path to probe after rollout (default: /healthz)
#   SKIP_HEALTH_GATE  Set to "1" to bypass the health gate (NOT recommended)

set -o errexit
set -o nounset
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib/logging.sh
source "${SCRIPT_DIR}/lib/logging.sh"
# shellcheck source=./lib/kubectl-helpers.sh
source "${SCRIPT_DIR}/lib/kubectl-helpers.sh"

main() {
    require_env SERVICE_NAME IMAGE K8S_NAMESPACE ENVIRONMENT
    require_cmd kubectl helm

    local chart_path="${CHART_PATH:-${SCRIPT_DIR}/../kubernetes/helm/app-chart}"
    local rollout_timeout="${ROLLOUT_TIMEOUT:-300}"
    local health_path="${HEALTH_PATH:-/healthz}"

    log::info "=== deploy ${SERVICE_NAME} → ${ENVIRONMENT} (${K8S_NAMESPACE}) ==="
    log::info "image:   ${IMAGE}"
    log::info "chart:   ${chart_path}"

    local snapshot_dir=""
    if kubectl --namespace "${K8S_NAMESPACE}" get \
            "deployment/${SERVICE_NAME}" >/dev/null 2>&1; then
        log::info "existing deployment found — taking pre-deploy snapshot"
        snapshot_dir="$(k8s::snapshot "${K8S_NAMESPACE}" "${SERVICE_NAME}")"
        log::ok  "snapshot saved at ${snapshot_dir}"
    else
        log::info "no existing deployment — first install"
    fi

    local helm_args=(
        upgrade --install "${SERVICE_NAME}" "${chart_path}"
        --namespace "${K8S_NAMESPACE}"
        --create-namespace
        --set "image.repository=${IMAGE%:*}"
        --set "image.tag=${IMAGE##*:}"
        --set "environment=${ENVIRONMENT}"
        --set "serviceName=${SERVICE_NAME}"
        --atomic
        --timeout "${rollout_timeout}s"
        --history-max 10
    )
    if [[ -n "${VALUES_FILE:-}" ]]; then
        helm_args+=(--values "${VALUES_FILE}")
    fi

    log::run helm "${helm_args[@]}"

    k8s::wait_rollout "${K8S_NAMESPACE}" "${SERVICE_NAME}" "${rollout_timeout}"

    if [[ "${SKIP_HEALTH_GATE:-0}" == "1" ]]; then
        log::warn "SKIP_HEALTH_GATE=1 → bypassing post-deploy health probe"
    else
        if ! k8s::probe_service "${K8S_NAMESPACE}" "${SERVICE_NAME}" "${health_path}"; then
            log::error "health gate failed — initiating auto-rollback"
            if [[ -n "${snapshot_dir}" ]]; then
                SNAPSHOT_PATH="${snapshot_dir}" \
                    "${SCRIPT_DIR}/rollback.sh"
            else
                log::warn "no snapshot available (first install) — uninstalling release"
                helm uninstall "${SERVICE_NAME}" --namespace "${K8S_NAMESPACE}" || true
            fi
            log::fatal "deploy aborted due to failing health gate"
        fi
    fi

    log::ok "=== deploy succeeded: ${SERVICE_NAME} @ ${IMAGE} ==="
}

main "$@"
