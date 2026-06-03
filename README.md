# Pipeline Automation Suite

A batteries-included set of **reusable CI/CD building blocks** for product teams
that ship containerised services to Kubernetes. The suite combines:

- **Azure DevOps** YAML templates (jobs / stages / steps)
- **Bitbucket Pipelines** shared definitions and custom pipes
- **Terraform** modules for the underlying cloud platform (AKS, ACR, Key Vault,
  networking)
- **Kubernetes** manifests (Kustomize base/overlays + Helm chart)
- **Bash** automation: deploy, health-check, secrets sync and **automated
  rollback** with versioned snapshots
- Opinionated **secrets management** flow backed by Azure Key Vault / HashiCorp
  Vault

The suite is consumed as a *single source of truth* by multiple product teams.
Each team writes a tiny pipeline file (~30 lines) that imports the templates and
selects an environment — everything else (build, scan, deploy, smoke test,
rollback) is handled by the shared assets.

---

## Repository layout

```
pipeline-automation-suite/
├── azure-devops/         # ADO templates + example consumer pipelines
├── bitbucket/            # Bitbucket shared YAML + custom pipes
├── terraform/            # Modules + environment stacks (dev/staging/prod)
├── kubernetes/           # Kustomize base/overlays + Helm chart
├── scripts/              # Bash automation (deploy, rollback, health, secrets)
├── examples/sample-app/  # End-to-end example consumer
└── docs/                 # Architecture, adoption, secrets, rollback guides
```

---

## Quick start (consumer team)

1. Add this repo as a Git submodule or reference it as an Azure DevOps
   `repositories` resource / Bitbucket `import` source.
2. Drop one of the example consumer pipelines into your service repository
   (`examples/sample-app/azure-pipelines.yml` or `bitbucket-pipelines.yml`).
3. Populate the variables (`SERVICE_NAME`, `IMAGE_REPO`, `K8S_NAMESPACE`,
   environment selector) and push — that's it.

See [`docs/ADOPTION.md`](docs/ADOPTION.md) for the full team onboarding flow.

---

## Highlights

- **One pipeline shape across two CI systems.** Teams migrating between Azure
  DevOps and Bitbucket reuse the same Bash core and the same Kubernetes
  delivery contract.
- **Versioned rollbacks.** Every deploy snapshots the previous `Deployment` and
  ConfigMap revisions to an ACR-backed artifact. `scripts/rollback.sh` (and the
  `rollback.yml` job template) restores them atomically and verifies health.
- **Secrets never touch CI logs.** Secrets are resolved at runtime from Azure
  Key Vault via the `AzureKeyVault@2` task / `secrets-sync.sh` and mounted as
  Kubernetes `Secret` objects through CSI driver.
- **Terraform-driven platform.** All cloud infra — AKS clusters, ACR, Key
  Vaults, networking — is reproducible per environment via `terraform/`.

---

## Local development

```bash
# Lint Bash scripts
shellcheck scripts/*.sh scripts/lib/*.sh

# Validate Terraform modules
terraform -chdir=terraform/environments/dev init -backend=false
terraform -chdir=terraform/environments/dev validate

# Render Helm chart
helm template ./kubernetes/helm/app-chart \
  --values examples/sample-app/values.yaml

# Run Bash unit tests
bats scripts/tests/
```

---

## License

MIT — see [`LICENSE`](LICENSE).
