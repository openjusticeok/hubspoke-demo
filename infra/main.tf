terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }

  backend "gcs" {
    # Bucket configured via -backend-config flag in CI
    prefix = "infra"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Enable required APIs
resource "google_project_service" "artifact_registry" {
  project = var.project_id
  service = "artifactregistry.googleapis.com"
}

resource "google_project_service" "cloud_run" {
  project = var.project_id
  service = "run.googleapis.com"
}

resource "google_project_service" "compute" {
  project = var.project_id
  service = "compute.googleapis.com"
}

# VPC Network for GCE instances
resource "google_compute_network" "vpc" {
  depends_on              = [google_project_service.compute]
  name                    = "hubspoke-vpc"
  auto_create_subnetworks = true
}

# Artifact Storage
resource "google_storage_bucket" "nixos_images" {
  name                     = var.artifact_bucket
  location                 = "US"
  force_destroy            = true
  public_access_prevention = "enforced"
}

resource "google_artifact_registry_repository" "app_repo" {
  depends_on    = [google_project_service.artifact_registry]
  location      = var.region
  repository_id = "repo"
  format        = "DOCKER"
}

# Allow the tofu-provisioner service account to push images to Artifact Registry
resource "google_artifact_registry_repository_iam_member" "repo_writer" {
  depends_on = [google_artifact_registry_repository.app_repo]
  repository = google_artifact_registry_repository.app_repo.id # Use .id not .name for full resource path
  location   = var.region
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${var.service_account}"
}

# Required for Workload Identity Federation token generation
resource "google_project_iam_member" "provisioner_token_creator" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${var.service_account}"
}

# Cloud Run Service
resource "google_cloud_run_service" "api" {
  depends_on = [google_project_service.cloud_run]
  name       = "hubspoke-demo"
  location   = var.region

  template {
    metadata {
      annotations = {
        # Allow up to 10 minutes for the container to start (R + plumber can be slow)
        "run.googleapis.com/startup-cpu-boost" = "true"
      }
    }

    spec {
      containers {
        image = "us-central1-docker.pkg.dev/${var.project_id}/repo/hubspoke-demo:${var.image_version}"

        env {
          name  = "ENVIRONMENT"
          value = var.environment
        }

        env {
          name  = "IMAGE_VERSION"
          value = var.image_version
        }

        ports {
          container_port = 8080
        }

        resources {
          limits = {
            cpu    = "2000m"
            memory = "1Gi"
          }
        }

        # Startup probe - give container 5 minutes to start
        startup_probe {
          initial_delay_seconds = 10
          period_seconds        = 10
          timeout_seconds       = 5
          failure_threshold     = 30 # 30 * 10s = 300s = 5 minutes
          success_threshold     = 1

          http_get {
            path = "/healthz"
            port = 8080
          }
        }
      }

      service_account_name = var.service_account
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

# Cloud Run IAM
resource "google_cloud_run_service_iam_member" "public" {
  service  = google_cloud_run_service.api.name
  location = google_cloud_run_service.api.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# GCE Image
resource "google_compute_image" "nixos" {
  depends_on = [google_storage_bucket.nixos_images]
  name       = "hubspoke-demo-${var.image_version}"

  raw_disk {
    source = "https://storage.googleapis.com/${var.artifact_bucket}/nixos-image-${var.image_version}.tar.gz"
  }

  guest_os_features {
    type = "UEFI_COMPATIBLE"
  }

  guest_os_features {
    type = "GVNIC"
  }

  labels = {
    version     = var.image_version
    environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Optional: GCE Instance
resource "google_compute_instance" "api" {
  depends_on   = [google_compute_network.vpc]
  count        = var.deploy_vm ? 1 : 0
  name         = "hubspoke-demo-${var.environment}"
  machine_type = "e2-medium"
  zone         = "${var.region}-a"

  boot_disk {
    initialize_params {
      image = google_compute_image.nixos.self_link
    }
  }

  network_interface {
    network = google_compute_network.vpc.self_link
    access_config {}
  }

  metadata = {
    environment   = var.environment
    image_version = var.image_version
  }

  labels = {
    environment = var.environment
    version     = var.image_version
  }
}

# Service account passed via tfvars variable
