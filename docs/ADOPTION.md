# Team Adoption Guide

This is the playbook a new product team follows to onboard their service to
the suite. Goal: a fully wired CI/CD pipeline in under one hour.

## 1. Prerequisites (one-off, platform team)

- Azure DevOps project with this repo registered as a `repositories` resource
  **or** Bitbucket workspace with this repo accessible.
- A service connection (`azureSubscription`) bound to the platform
  subscription.
- A namespace per env created by `terraform/environments/<env>` already
  applied (`aks-platform-dev`, `aks-platform-staging`, `aks-platform-prod`).
- Approvals configured on Azure DevOps Environments named
  `<service>-<env>` (e.g. `sample-api-prod`).

## 2. Per-service setup (5 minutes)

1. Copy the contents of `examples/sample-app/` into your service repo:

   ```
   azure-pipelines.yml      # or bitbucket-pipelines.yml
   secrets.manifest
   values.yaml
   ```

2. Edit the three placeholders in the pipeline file:
   - `serviceName`
   - `imageRepo`
   - The three `k8sNamespace` values (one per env).

3. Populate `secrets.manifest` with the keys your service needs. The names on
   the right-hand side are the secret names inside Azure Key Vault. Ask the
   platform team to create them via Terraform.

4. Push to `main`. The pipeline auto-triggers and runs all stages up to the
   first manual approval (staging).

## 3. What happens on every push

| Stage              | Run when           | Notes                                        |
| ------------------ | ------------------ | -------------------------------------------- |
| Lint & test        | every commit       | shellcheck + bats + service-level tests      |
| Build + scan       | every commit       | Trivy gate fails on HIGH/CRITICAL CVEs       |
| Deploy → dev       | every commit on main | Fully automated, snapshot taken           |
| Deploy → staging   | manual approval    | Same flow, env environment in ADO            |
| Deploy → prod      | manual approval    | Same flow, with extra approvers              |
| Rollback           | manual or auto     | See `docs/ROLLBACK.md`                       |

## 4. Day-2 operations

- **Pin a new suite version**: bump `ref: refs/tags/vX.Y.Z` in the consumer
  pipeline. Teams choose when to upgrade.
- **Add a secret**: append a line to `secrets.manifest` and ask the platform
  team to create the matching Key Vault secret.
- **Run a hot-fix without rebuilding**: trigger the `custom: rollback-prod`
  pipeline (Bitbucket) or the `rollback.yml` job (ADO).

## 5. Adoption metrics we track

- Mean time to first green build per new service (target ≤ 30 min).
- Number of services on the suite vs. legacy bespoke pipelines.
- % of failed prod deploys that triggered automated rollback (target = 100%).
