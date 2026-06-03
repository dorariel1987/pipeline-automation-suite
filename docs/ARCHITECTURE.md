# Architecture

## Overview

The suite separates **platform code** (this repo) from **service code** (each
product team's repo). A service repo contains only a thin pipeline file that
imports stages from this repo and feeds them service-specific values. All
heavy lifting — build, scan, secrets, deploy, snapshot, rollback — lives here.

```
+--------------------+        imports        +---------------------------+
| Service repository |  ───────────────────▶ | pipeline-automation-suite |
| (sample-api etc.)  |                       |  (this repo)              |
| azure-pipelines.yml|                       |  + ADO templates          |
| bitbucket-pipelines|                       |  + Bitbucket pipes        |
| values.yaml        |                       |  + Helm chart             |
| secrets.manifest   |                       |  + Bash scripts           |
+--------------------+                       +---------------------------+
                                                         │
                                                         ▼
                                            +---------------------------+
                                            | Terraform-managed platform|
                                            | AKS, ACR, Key Vault, VNet |
                                            +---------------------------+
```

## Component responsibilities

| Layer        | Component                          | Responsibility                                      |
| ------------ | ---------------------------------- | --------------------------------------------------- |
| CI – ADO     | `azure-devops/templates/stages/ci` | Lint, unit tests, container build, vuln scan, push  |
| CI – BB      | `bitbucket/shared/definitions`     | Same surface, anchors for branches/PR pipelines     |
| CD – ADO     | `azure-devops/templates/stages/cd` | Per-env approval gate → secrets sync → deploy       |
| CD – BB      | `bitbucket/pipes/k8s-deployer`     | Manual-triggered deploy with rollback fallback      |
| Delivery     | `kubernetes/helm/app-chart`        | One generic chart that fits >90% of services        |
| Automation   | `scripts/deploy.sh` `rollback.sh`  | Idempotent core invoked by every CI system          |
| Platform     | `terraform/`                       | AKS + ACR + Key Vault + Networking per environment  |
| Adoption     | `examples/sample-app`              | Reference implementation for teams to copy/paste    |

## Deploy flow (single environment)

```
+--------+   +------------+   +------------+   +---------------+   +-----------+
| Build  |──▶| Vuln Scan  |──▶| Sync       |──▶| Snapshot      |──▶| Helm      |
| Image  |   | (Trivy)    |   | Secrets    |   | Deployment    |   | upgrade   |
+--------+   +------------+   +------------+   +---------------+   +-----+-----+
                                                                         │
                                                                  ┌──────┴──────┐
                                                                  │ Health gate │
                                                                  └──────┬──────┘
                                                                         │
                                                       pass ◀────────────┴────────────▶ fail
                                                         │                                │
                                                         ▼                                ▼
                                                +-----------------+              +------------------+
                                                | Publish snapshot|              | rollback.sh      |
                                                | as CI artifact  |              | restore snapshot |
                                                +-----------------+              | + re-probe       |
                                                                                 +------------------+
```

## Why a Bash core instead of two YAML codebases

Both Azure DevOps and Bitbucket have their own quirks but both can invoke a
shell. Centralising `deploy.sh` / `rollback.sh` / `secrets-sync.sh` means:

1. One battle-tested code path for both CI systems.
2. Local execution for engineers (`ENVIRONMENT=dev ./scripts/deploy.sh`).
3. Easy unit tests with **bats** (see `scripts/tests`).
4. Trivial migration between Bitbucket Cloud and Azure DevOps without
   reworking the deploy logic.
