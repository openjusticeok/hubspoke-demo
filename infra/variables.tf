variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "us-central1"
}

variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
}

variable "image_version" {
  description = "Version identifier (SHA or tag) for the artifact. Changing this triggers new resource creation."
  type        = string
}

variable "staging_bucket" {
  description = "GCS bucket for NixOS images"
  type        = string
}

variable "service_account" {
  description = "Service account email for Tofu to use for deployment"
  type        = string
}

variable "deploy_vm" {
  description = "Whether to deploy a GCE VM instance in addition to Cloud Run"
  type        = bool
  default     = true
}
