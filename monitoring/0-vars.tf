variable "project_id" {
  default = "kubernetesmonitoringprometheus"
}
variable "region" {
  default = "us-central1"
}
variable "service_account" {
    default = "monitoring@kubernetesmonitoringprometheus.iam.gserviceaccount.com"
}
locals {
  api=[
    "iam.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "monitoring.googleapis.com",
    "logging.googleapis.com"
  ]
}