# Production Environment Configuration
# Protected by CODEOWNERS - requires approval from @brancengregory

project_id      = "hubspoke-demo-prod-f01c"
service_account = "tofu-provisioner@hubspoke-demo-prod-f01c.iam.gserviceaccount.com"
staging_bucket  = "hubspoke-demo-prod-nixos-images"
image_version   = "PLACEHOLDER"
region          = "us-central1"
environment     = "prod"
deploy_vm       = true
