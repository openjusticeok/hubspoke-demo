# Development Environment Configuration
# NOTE: image_version is passed dynamically via -var flag in CI/CD pipeline
# This avoids circular triggers from committing version changes to git

project_id      = "hubspoke-demo-dev-b87d"
service_account = "tofu-provisioner@hubspoke-demo-dev-b87d.iam.gserviceaccount.com"

# Tofu State Backend (managed by infrastructure repo)
state_bucket = "hubspoke-demo-dev-tfstate"

# Artifact Storage (for NixOS images)
artifact_bucket = "hubspoke-demo-dev-nixos-images"

# Default value - overridden by CI/CD pipeline with actual build SHA
image_version = "latest"
region        = "us-central1"
environment   = "dev"
deploy_vm     = true
