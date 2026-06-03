#!/usr/bin/env bash
# Entrypoint for the k8s-deployer Bitbucket pipe.
set -o errexit
set -o nounset
set -o pipefail

source /opt/suite/scripts/lib/logging.sh

[[ "${DEBUG:-false}" == "true" ]] && export LOG_LEVEL=debug

log::info "pipe k8s-deployer starting for ${SERVICE_NAME} (${ENVIRONMENT})"

require_env SERVICE_NAME IMAGE K8S_NAMESPACE ENVIRONMENT \
            AKS_CLUSTER AKS_RESOURCE_GROUP \
            AZURE_SP_ID AZURE_SP_SECRET AZURE_TENANT_ID

az login --service-principal \
    -u "${AZURE_SP_ID}" \
    -p "${AZURE_SP_SECRET}" \
    --tenant "${AZURE_TENANT_ID}" >/dev/null

az aks get-credentials \
    --resource-group "${AKS_RESOURCE_GROUP}" \
    --name "${AKS_CLUSTER}" \
    --overwrite-existing

/opt/suite/scripts/deploy.sh
