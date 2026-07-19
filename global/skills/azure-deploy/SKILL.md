---
name: azure-deploy
description: Deploy serverless container applications to Azure Container Apps using Azure CLI.
disable-model-invocation: true
---

# Azure Container Apps deploy

Deploy a container image to an existing Azure Container App with zero downtime. Inputs: $ARGUMENTS (resource group, app name, image ref + tag). If any is missing, ask before touching Azure.

## Procedure
1. **Pre-flight**
   - `az --version` — Azure CLI present and logged in (`az account show`); if not, stop and give the exact login step.
   - `git status --short` — refuse to deploy a dirty working tree unless the user explicitly overrides.
   - Confirm the target: resource group, container app name, and the exact `image:tag` to ship (no `latest` — pin an immutable tag).
2. **Deploy (zero-downtime)**
   - `az containerapp update -g <rg> -n <app> --image <registry>/<repo>:<tag>` — Container Apps creates a new revision and shifts traffic once it is healthy; the previous revision keeps serving until then.
3. **Verify health**
   - `az containerapp show -g <rg> -n <app> --query properties.configuration.ingress.fqdn -o tsv` → resolve the FQDN, then probe its health endpoint with bounded retries/timeout until it returns healthy.
4. **Report**
   - `az containerapp revision list -g <rg> -n <app> -o table` — list active revisions, traffic weights and provisioning/running state; state which revision is live and whether the rollout succeeded.
   - On failure, surface the failing revision and the rollback command: `az containerapp ingress traffic set -g <rg> -n <app> --revision-weight <previous-revision>=100`.
