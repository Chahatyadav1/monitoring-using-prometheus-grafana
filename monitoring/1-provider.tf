terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "7.9.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.38.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "3.1.0"
    }
  }
}

provider "google" {
  project = var.project_id
}
provider "kubernetes" {
  host  = "https://${google_container_cluster.primary.endpoint}"
  token = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(
    google_container_cluster.primary.master_auth[0].cluster_ca_certificate
  )
}

provider "helm" {
  kubernetes = {
    host  = "https://${google_container_cluster.primary.endpoint}"
    token = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(
      google_container_cluster.primary.master_auth[0].cluster_ca_certificate
    )
  }
}

data "google_client_config" "default" {}

resource "google_project_service" "api" {
  project            = var.project_id
  for_each           = toset(local.api)
  service            = each.key
  disable_on_destroy = false
}
