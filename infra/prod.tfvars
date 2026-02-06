# Production Environment Configuration
# Protected by CODEOWNERS - requires approval from @brancengregory

project_id      = "hubspoke-demo-prod-f01c"
service_account = "tofu-provisioner@hubspoke-demo-prod-f01c.iam.gserviceaccount.com"

# Tofu State Backend (managed by infrastructure repo)
state_bucket = "hubspoke-demo-prod-tfstate"

# Artifact Storage (for NixOS images)
artifact_bucket = "hubspoke-demo-prod-nixos-images"

# Git SHA from dev build (both container and GCE image exist at this version)
image_version = "935b9e1"
region        = "us-central1"
environment   = "prod"
deploy_vm     = true

