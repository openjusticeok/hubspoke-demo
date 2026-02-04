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
1. Push to `main` branch
2. CI builds Nix artifacts with git SHA
3. CI commits update to `infra/dev.tfvars` with new SHA
4. Auto-deploys to dev environment

### Production Promotion
1. Create PR updating `infra/prod.tfvars` with SHA from dev
2. CI runs plan and posts results
3. CODEOWNERS approval required (@brancengregory)
4. Merge triggers deployment to prod

## Configuration as Data

All environment configuration is in version-controlled tfvars files:

- `infra/dev.tfvars` - Dev environment (auto-updated)
- `infra/prod.tfvars` - Production (protected by CODEOWNERS)

## Required Setup

1. **GitHub Secrets:**
   - `GCP_WIF_PROVIDER` - Workload Identity Provider resource name

2. **Branch Protection:**
   - Enable "Require pull request reviews"
   - Enable "Require review from Code Owners"

3. **CODEOWNERS:** Already configured to protect `infra/prod.tfvars`

## Infrastructure

Built on `openjusticeok/tofu-modules` v0.6.0+ with:
- Hub & Spoke WIF (single global identity pool)
- Versioned artifacts (SHA-based immutable deployments)
- Dual deployment (Cloud Run container + GCE VM)
- Separate state buckets per environment

## License

MIT
