# Rollback

## When does a rollback happen

| Trigger                                  | How                                          |
| ---------------------------------------- | -------------------------------------------- |
| Health gate fails after `helm upgrade`   | `deploy.sh` invokes `rollback.sh` in-process |
| `helm upgrade --atomic` rolls itself     | Helm reverts; CI marks the job failed         |
| Operator clicks "Run pipeline" on rollback | ADO `jobs/rollback.yml` or Bitbucket `custom: rollback-prod` |
| Engineer on a laptop with kubeconfig     | `SERVICE_NAME=... K8S_NAMESPACE=... ./scripts/rollback.sh` |

## Two restore strategies

### A. Snapshot restore (preferred)

Before each deploy, `deploy.sh` calls `k8s::snapshot` which writes the live
`Deployment` YAML (and ConfigMap references) under
`$SNAPSHOT_DIR/<namespace>/<deployment>/<timestamp>/`. The CI step then
publishes the directory as a pipeline artifact.

On rollback we `kubectl apply` the saved `deployment.yaml` — this gives us a
**bit-exact restore** that includes any out-of-band kubectl edits made between
deploys.

### B. `kubectl rollout undo` (fallback)

If no snapshot path is supplied, `rollback.sh` looks up the previous revision
via `kubectl rollout history` and runs `rollout undo --to-revision=N`. This is
sufficient for the common case where the only thing that changed is the image
tag.

## Verifying a rollback

`rollback.sh` does three things before declaring success:

1. Waits for `kubectl rollout status` to settle (default 300s).
2. Locates a pod with the service label.
3. Probes `${HEALTH_PATH}` (default `/healthz`) from within the cluster and
   asserts the expected status.

If any check fails the script exits non-zero and the calling CI job fails.
The platform PagerDuty receiver then opens an incident — manual intervention
required.

## Post-rollback hooks

Set `POST_HOOK` to an executable path to fire notifications (Slack, MS Teams,
PagerDuty) after a successful rollback:

```bash
POST_HOOK=/usr/local/bin/notify-slack \
SERVICE_NAME=sample-api K8S_NAMESPACE=sample-api-prod \
./scripts/rollback.sh
```

## SLOs

- Rollback completes within **3 minutes** for 95% of services.
- Zero leaked secrets across all rollback paths (audited via `kubectl
  describe secret`).
- 100% of failed prod deploys must result in either a successful rollback or
  a paged incident — silent failures are a release blocker.
