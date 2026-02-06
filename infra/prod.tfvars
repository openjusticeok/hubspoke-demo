# Production Environment Configuration
# Protected by CODEOWNERS - requires approval from @brancengregory
#
# MANUAL PROMOTION WORKFLOW:
# 1. Check latest successful dev build in GitHub Actions (SHA shown in workflow output)
# 2. Verify that SHA has both artifacts in dev:
#    - Container: us-central1-docker.pkg.dev/hubspoke-demo-dev-b87d/repo/hubspoke-demo:[SHA]
#    - GCE Image: gs://hubspoke-demo-dev-nixos-images/nixos-image-[SHA].tar.gz
# 3. Update image_version below with that full SHA (40 characters)
# 4. Commit and push - triggers promotion workflow
# 5. Workflow will: copy artifacts to prod, deploy to Cloud Run + GCE
#
# Current SHA: c5668ae (verified in dev, has both container and GCE image)

project_id      = "hubspoke-demo-prod-f01c"
service_account = "tofu-provisioner@hubspoke-demo-prod-f01c.iam.gserviceaccount.com"

# Tofu State Backend (managed by infrastructure repo)
state_bucket = "hubspoke-demo-prod-tfstate"

# Artifact Storage (for NixOS images)
artifact_bucket = "hubspoke-demo-prod-nixos-images"

# Version to deploy - must match a successful dev build (update manually)
image_version = "65420381db0fd045aa5070f0da43abfc9fa94376"
region        = "us-central1"
environment   = "prod"
deploy_vm     = true

