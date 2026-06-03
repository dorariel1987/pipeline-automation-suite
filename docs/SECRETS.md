# Secrets Management

## Principles

1. **Secrets never appear in pipeline logs.** All retrievals use the silent
   `--query value -o tsv` form of the Azure CLI, and `base64` happens
   on stdin.
2. **Secrets never live in Git.** Only the *mapping* between an env-var name
   and a vault key (`secrets.manifest`) is checked in.
3. **One vault per environment.** `kv-platform-dev`, `kv-platform-staging`,
   `kv-platform-prod`. Each AKS cluster's kubelet identity has
   `Key Vault Secrets User` on its environment's vault only.
4. **Rotation is a no-op for services.** Rotate the value in Key Vault; on the
   next deploy the pipeline regenerates the `Secret` and triggers a rollout.

## How it works

```
+----------------+    1. read manifest    +-----------------+
| secrets.manifest| ────────────────────▶ | secrets-sync.sh |
+----------------+                        +--------+--------+
                                                   │ 2. az keyvault secret show
                                                   ▼
                                          +-----------------+
                                          | Azure Key Vault |
                                          +--------+--------+
                                                   │ 3. base64-encoded values
                                                   ▼
                                          +-----------------+
                                          | kubectl apply   |
                                          | Secret <svc>-secrets
                                          +-----------------+
                                                   │ 4. mounted via envFrom
                                                   ▼
                                          +-----------------+
                                          | App container   |
                                          +-----------------+
```

## Backends

Set `VAULT_BACKEND=azure` (default) or `VAULT_BACKEND=hcv`:

### Azure Key Vault

```bash
export VAULT_BACKEND=azure
export AZURE_KEYVAULT=kv-platform-prod
export SECRETS_MANIFEST=./secrets.manifest
export SECRET_NAME=sample-api-secrets
export K8S_NAMESPACE=sample-api-prod
./scripts/secrets-sync.sh
```

### HashiCorp Vault (KV-v2)

```bash
export VAULT_BACKEND=hcv
export HCV_MOUNT=kv
export HCV_PATH=prod/sample-api
export VAULT_ADDR=https://vault.platform.internal
export VAULT_TOKEN=...
./scripts/secrets-sync.sh
```

## CSI Secrets Store alternative

For services that want secrets mounted as files (rather than env vars) the
Helm chart can be extended with an `azureKeyVaultProviderClass`. The platform
team enables the `azure-keyvault-secrets-provider` AKS add-on globally; teams
opt in by setting `azureWorkloadIdentityClientId` in their `values.yaml`.

## What to do on a leak

1. Rotate the value in Key Vault immediately.
2. Trigger the standard CD pipeline — `secrets-sync.sh` will refresh the
   Kubernetes Secret and roll the pods automatically because the
   `checksum/config` pod annotation changes.
3. Run `kubectl --namespace <ns> get events --field-selector reason=Killing`
   to confirm the rollout completed.
