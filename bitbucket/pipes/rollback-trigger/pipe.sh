#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

source /opt/suite/scripts/lib/logging.sh

require_env SERVICE_NAME K8S_NAMESPACE \
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

/opt/suite/scripts/rollback.sh
