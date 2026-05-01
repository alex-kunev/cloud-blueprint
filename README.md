# Cloud Blueprint

A self-service infrastructure provisioning platform that lets teams deploy pre-approved Azure infrastructure templates through a web UI — no Terraform knowledge required.

## How it works

1. A developer opens the **Portal** (GitHub Pages) and fills out a short form: project name, stack type, environment, owner, and cost center.
2. The portal dispatches a **GitHub Actions workflow** via the GitHub API.
3. The workflow runs Terraform to provision the chosen **stack** on Azure, using shared **modules** for consistent resource configuration.
4. Terraform outputs (endpoints, resource names) are uploaded to Azure Blob Storage and surfaced back in the portal.

Production deployments are environment-gated and require manual approval before apply.

## Repository layout

```
.
├── portal/          # Self-service web UI (GitHub Pages)
├── stacks/
│   └── webapi/      # Terraform stack: resource group, networking, Key Vault, Cosmos DB
├── modules/
│   ├── networking/  # VNet, subnets, service endpoints
│   ├── key-vault/   # Key Vault with RBAC and network ACLs
│   ├── cosmos/      # Cosmos DB (serverless, VNet-filtered)
│   └── app-service/ # Linux App Service with managed identity (optional)
├── .github/
│   └── workflows/
│       ├── provision.yml      # Infrastructure provisioning pipeline
│       └── deploy-portal.yml  # Portal deployment to GitHub Pages
└── .provision.yml   # Default provisioning config for push-triggered runs
```

## Stacks

| Stack | Resources |
|---|---|
| `webapi` | Resource Group, VNet/Subnets, Key Vault, Cosmos DB (serverless) |

Additional stacks (worker, static-site) are stubs — they appear as disabled options in the portal UI.

## Prerequisites

- Azure subscription with a resource group and storage account for Terraform remote state
- GitHub repository with:
  - OIDC workload identity federation configured for Azure (no stored credentials)
  - The secrets listed below
  - GitHub Pages enabled (for the portal)
  - A `prod` environment with required reviewers configured (for production approval gates)

### Required secrets

| Secret | Description |
|---|---|
| `AZURE_CLIENT_ID` | Client ID of the federated service principal |
| `AZURE_TENANT_ID` | Azure AD tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Target Azure subscription ID |
| `TF_STATE_RG` | Resource group containing the Terraform state storage account |
| `TF_STATE_SA` | Storage account name for Terraform state |
| `PORTAL_DISPATCH_TOKEN` | Classic GitHub PAT with the `workflow` scope — the built-in `GITHUB_TOKEN` cannot dispatch workflows |

## Usage

### Via the portal (recommended)

Open `https://<owner>.github.io/<repo>/` and complete the form. The portal polls for workflow status and displays Terraform outputs once provisioning completes.

### Via GitHub Actions manually

Go to **Actions → provision.yml → Run workflow** and supply inputs:

| Input | Default (from `.provision.yml`) | Description |
|---|---|---|
| `stack_type` | `webapi` | Stack template to deploy |
| `project_name` | `my-project` | Lowercase alphanumeric + hyphens, max 20 chars |
| `environment` | derived from branch | `dev` or `prod` |
| `owner_tag` | `platform-team` | Resource ownership tag |
| `cost_center_tag` | `CC-1042` | Cost allocation tag |

### Via git push (GitOps)

Push to `develop` → provisions to **dev**.  
Push to `main` → provisions to **prod** (requires approval).

Only triggers when files under `stacks/`, `modules/`, or `.provision.yml` change.

## Terraform state

State is stored remotely in Azure Blob Storage, isolated per project and environment:

```
<storage-account>/tfstate/<project_name>-<environment>.tfstate
```

Terraform outputs are uploaded separately to a `provisioner-outputs` container for the portal to read.

## Local development

### Portal

```bash
cp portal/config.js portal/config.local.js
# Edit config.local.js — fill in githubOwner, githubRepo, githubToken
# Open portal/index.html in a browser (or serve with any static HTTP server)
```

`config.local.js` is gitignored. Never commit real tokens to `config.js`.

### Terraform

```bash
cd stacks/webapi

terraform init \
  -backend-config="resource_group_name=<TF_STATE_RG>" \
  -backend-config="storage_account_name=<TF_STATE_SA>" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=my-project-dev.tfstate"

terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

Requires Azure credentials in your environment (`az login` or environment variables).

## Design notes

- **OIDC authentication** — CI/CD uses workload identity federation; no long-lived secrets stored in GitHub.
- **VNet isolation** — All resources are deployed inside a virtual network with service endpoints; Key Vault network ACLs restrict access to provisioned subnets.
- **Cosmos DB serverless** — Zero cost at idle; no provisioned throughput to manage.
- **Managed identity** — App Service accesses Key Vault via Azure AD; no passwords stored.
- **State isolation** — Each project + environment pair has its own state file to prevent blast radius.
- **Zero-backend portal** — The portal is a static site with no server; all logic runs client-side against the GitHub API.
