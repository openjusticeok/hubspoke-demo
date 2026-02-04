# Hub and Spoke Demo

A complete demonstration of the OpenJustice OK platform engineering stack, featuring:

- **Hub & Spoke Identity** - Centralized Workload Identity Federation
- **NixOS + Container** - Immutable infrastructure with versioned artifacts  
- **GitOps Deployment** - Explicit SHA-based promotions via PRs
- **Multi-Environment** - Dev (auto-deploy) and Prod (approval gates)

## Architecture

```
┌─────────────┐         ┌─────────────┐
│     Dev     │────────▶│   Prod      │
│  (auto)     │         │  (manual)   │
└─────────────┘         └─────────────┘
      │                       │
      ▼                       ▼
  hubspoke-             hubspoke-
  demo-dev              demo-prod
```

## Quick Start

### Initial Setup (One-time)

**⚠️ IMPORTANT: Landing Zone must be created manually before CI/CD will work.**

This project separates infrastructure into two layers:

1. **Landing Zone (Base Infrastructure)** - Provisioned manually once
2. **Application Zone (App + Updates)** - Automated via CI/CD

**Step 1: Provision Landing Zone**

Run this locally to create the base infrastructure:

```bash
cd infra
tofu init -backend-config="bucket=hubspoke-demo-dev-tfstate"
tofu apply -var-file="dev.tfvars" -var="image_version=initial"
```

This creates:
- GCP API enablements (Artifact Registry, Cloud Run, etc.)
- GCS bucket for NixOS images
- Artifact Registry repository
- IAM permissions for the CI/CD service account

**Step 2: Build Initial Image (Optional)**

The first CI/CD run will fail because Cloud Run expects an image that doesn't exist yet.
You can either:
- Let the first CI/CD run fail, then re-run it after the image is pushed
- Manually build and push an initial image:

```bash
nix run .#container.copyToDockerDaemon
docker tag hubspoke-demo:latest us-central1-docker.pkg.dev/hubspoke-demo-dev-b87d/repo/hubspoke-demo:initial
skopeo copy docker-daemon:us-central1-docker.pkg.dev/hubspoke-demo-dev-b87d/repo/hubspoke-demo:initial \
  docker://us-central1-docker.pkg.dev/hubspoke-demo-dev-b87d/repo/hubspoke-demo:initial
```

**Step 3: Enable CI/CD**

After the landing zone is ready, pushes to `main` will automatically:
1. Build container and GCE images via Nix
2. Push to Artifact Registry and GCS
3. Deploy to dev environment via OpenTofu

### Development Workflow

```bash
# Enter development environment
nix develop

# Build artifacts
mise run build

# Deploy locally (requires GCP auth)
mise run deploy-local
```

## API Endpoints

- `GET /` - Hello message with version and environment info
- `GET /healthz` - Health check (returns 200 OK)
- `GET /status` - Detailed system status
- `POST /echo` - Echo endpoint

## Deployment Flow

### Development (Auto-Deploy)

**Trigger:** Push to `main` branch (excluding `infra/prod.tfvars`)

**Flow:**
1. CI builds Nix artifacts with git SHA
2. Container pushed to `us-central1-docker.pkg.dev/.../hubspoke-demo:$SHA`
3. GCE image pushed to GCS
4. OpenTofu applies with `-var="image_version=$SHA"`
5. Cloud Run updated with new container

### Production Promotion

**Trigger:** Pull request modifying `infra/prod.tfvars` merged to `main`

**Flow:**
1. Create PR updating `infra/prod.tfvars` with SHA from dev
2. CODEOWNERS approval required (@brancengregory)
3. Merge triggers deployment
4. OpenTofu applies with version from `prod.tfvars`

## Configuration as Data

All environment configuration is in version-controlled tfvars files:

- `infra/dev.tfvars` - Dev environment (image_version overridden by CI)
- `infra/prod.tfvars` - Production (protected by CODEOWNERS, version pinned in git)

## Workflows

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `CI/CD: Dev` | Push to main (excl. prod.tfvars) | Build + deploy to dev |
| `Release: Production` | Push to main changing prod.tfvars | Deploy to prod |
| `CI` | Pull request | Validate tofu syntax |

## Required Setup

1. **GitHub Secrets:**
   - `GCP_WIF_PROVIDER` - Workload Identity Provider resource name

2. **Branch Protection:**
   - Enable "Require pull request reviews"
   - Enable "Require review from Code Owners"

3. **CODEOWNERS:** Already configured to protect `infra/prod.tfvars`

4. **Initial Landing Zone:** Must be provisioned manually (see Initial Setup above)

## Infrastructure

Built on `openjusticeok/tofu-modules` v0.6.0+ with:
- Hub & Spoke WIF (single global identity pool)
- Versioned artifacts (SHA-based immutable deployments)
- Dual deployment (Cloud Run container + GCE VM)
- Separate state buckets per environment

## License

MIT
