#!/usr/bin/env bash
# Thin wrappers around kubectl/helm used by deploy.sh and rollback.sh.
# Source after logging.sh.

# shellcheck source=./logging.sh
source "$(dirname "${BASH_SOURCE[0]}")/logging.sh"

# Wait for a Deployment to fully roll out.
# Usage: k8s::wait_rollout <namespace> <deployment> [timeout_seconds]
k8s::wait_rollout() {
    local namespace="$1"
    local deployment="$2"
    local timeout="${3:-300}"

    log::info "waiting for rollout: ${namespace}/${deployment} (timeout=${timeout}s)"
    if ! kubectl --namespace "${namespace}" rollout status \
            "deployment/${deployment}" --timeout="${timeout}s"; then
        log::error "rollout did not finish within ${timeout}s"
        return 1
    fi
    log::ok "rollout complete: ${namespace}/${deployment}"
}

# Capture a complete revision snapshot for later rollback.
# Returns the path to the snapshot directory on stdout.
# Usage: snapshot_dir="$(k8s::snapshot <namespace> <deployment>)"
k8s::snapshot() {
    local namespace="$1"
    local deployment="$2"
    local snapshot_root="${SNAPSHOT_DIR:-/tmp/k8s-snapshots}"
    local ts
    ts="$(date -u +"%Y%m%dT%H%M%SZ")"
    local dir="${snapshot_root}/${namespace}/${deployment}/${ts}"

    mkdir -p "${dir}"

    kubectl --namespace "${namespace}" get "deployment/${deployment}" \
        -o yaml > "${dir}/deployment.yaml"

    # Capture referenced configmaps and secrets (names only — values stay in Vault).
    kubectl --namespace "${namespace}" get "deployment/${deployment}" \
        -o jsonpath='{range .spec.template.spec.containers[*].envFrom[*]}{.configMapRef.name}{"\n"}{end}' \
        | sort -u | grep -v '^$' > "${dir}/configmap-refs.txt" || true

    printf "%s" "${dir}"
}

# Return the previous ReplicaSet revision number for a deployment.
k8s::previous_revision() {
    local namespace="$1"
    local deployment="$2"

    kubectl --namespace "${namespace}" rollout history \
        "deployment/${deployment}" | \
        awk 'NR>2 {print $1}' | sort -n | tail -2 | head -1
}

# Lightweight liveness probe against a Service's cluster IP.
# Usage: k8s::probe_service <namespace> <service> <path> [expected_status]
k8s::probe_service() {
    local namespace="$1"
    local service="$2"
    local path="$3"
    local expected="${4:-200}"

    local pod
    pod="$(kubectl --namespace "${namespace}" get pod -l app="${service}" \
        -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)"

    if [[ -z "${pod}" ]]; then
        log::warn "no pods found for service ${service} in ${namespace}"
        return 1
    fi

    local status
    status="$(kubectl --namespace "${namespace}" exec "${pod}" -- \
        sh -c "wget -q -O /dev/null -S 'http://${service}${path}' 2>&1 | \
               awk '/HTTP/ {print \$2; exit}'" || true)"

    if [[ "${status}" != "${expected}" ]]; then
        log::error "probe ${service}${path} returned ${status:-no-response}, expected ${expected}"
        return 1
    fi

    log::ok "probe ${service}${path} returned ${status}"
}
