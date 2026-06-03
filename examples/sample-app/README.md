# sample-app

End-to-end example showing what a product team adds to their service repo to
adopt the suite. Three files only:

- `azure-pipelines.yml` — wires the ADO suite templates
- `bitbucket-pipelines.yml` — equivalent for Bitbucket
- `secrets.manifest` — declarative mapping of env vars to vault keys
- `values.yaml` — per-service Helm overrides
