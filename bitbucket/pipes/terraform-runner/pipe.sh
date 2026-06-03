#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

source /opt/suite/scripts/lib/logging.sh

require_env TF_WORKDIR ENVIRONMENT ACTION \
            AZURE_SP_ID AZURE_SP_SECRET AZURE_TENANT_ID AZURE_SUBSCRIPTION_ID

export ARM_CLIENT_ID="${AZURE_SP_ID}"
export ARM_CLIENT_SECRET="${AZURE_SP_SECRET}"
export ARM_TENANT_ID="${AZURE_TENANT_ID}"
export ARM_SUBSCRIPTION_ID="${AZURE_SUBSCRIPTION_ID}"

cd "${TF_WORKDIR}"

case "${ACTION}" in
    plan)
        terraform fmt -check -recursive
        terraform init -input=false
        terraform validate
        terraform plan -input=false -out=tfplan -var "environment=${ENVIRONMENT}"
        log::ok "plan complete: ${TF_WORKDIR}/tfplan"
        ;;
    apply)
        terraform init -input=false
        if [[ -f tfplan ]]; then
            terraform apply -input=false -auto-approve tfplan
        else
            terraform apply -input=false -auto-approve -var "environment=${ENVIRONMENT}"
        fi
        log::ok "apply complete (${ENVIRONMENT})"
        ;;
    *)
        log::fatal "unsupported ACTION=${ACTION}"
        ;;
esac
