# k8s-deployer (Bitbucket pipe)

Wraps `scripts/deploy.sh` in a Bitbucket Pipe. Use it from any service repo
without having to install kubectl / helm yourself.

## Usage

```yaml
- step:
    name: Deploy → dev
    deployment: dev
    script:
      - pipe: pipelineautomationsuite/k8s-deployer:1.0.0
        variables:
          SERVICE_NAME: sample-api
          IMAGE: $IMAGE_REPO:$BITBUCKET_BUILD_NUMBER
          K8S_NAMESPACE: sample-api-dev
          ENVIRONMENT: dev
          AKS_CLUSTER: aks-dev-eastus
          AKS_RESOURCE_GROUP: rg-platform-dev
          AZURE_SP_ID: $AZURE_SP_ID
          AZURE_SP_SECRET: $AZURE_SP_SECRET
          AZURE_TENANT_ID: $AZURE_TENANT_ID
```

On failure the pipe attempts an in-process rollback using the snapshot it took
before the deploy. The snapshot is also exported as a Bitbucket artifact for
the separate `rollback-trigger` pipe.
