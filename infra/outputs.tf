output "cloud_run_url" {
  description = "The URL of the Cloud Run service"
  value       = google_cloud_run_service.api.status[0].url
}

output "gce_image_name" {
  description = "The name of the created GCE image"
  value       = google_compute_image.nixos.name
}

output "artifact_repository" {
  description = "The Artifact Registry repository URL"
  value       = "us-central1-docker.pkg.dev/${var.project_id}/repo"
}

output "image_version" {
  description = "The deployed image version"
  value       = var.image_version
}

output "environment" {
  description = "The deployment environment"
  value       = var.environment
}
