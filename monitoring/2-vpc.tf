resource "google_compute_network" "vpc_network" {
  project                 = var.project_id
  name                    = "vpc-network"
  auto_create_subnetworks = false
  mtu                     = 1460
  depends_on = [ google_project_service.api ]
}
resource "google_compute_subnetwork" "network-subnet-1" {
  name          = "monitoring-subnetwork"
  ip_cidr_range = "10.0.0.0/16"
  region        = "us-central1"
  network       = google_compute_network.vpc_network.id
  secondary_ip_range {
    range_name    = "nodes"
    ip_cidr_range = "10.1.0.0/16"
  }
    secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = "10.2.0.0/24"
  }
  depends_on = [ google_compute_network.vpc_network ]
}

resource "google_compute_firewall" "default" {
  name    = "monitoring-firewall"
  network = google_compute_network.vpc_network.name
    allow {
        protocol = "all"
    }
    source_ranges = ["0.0.0.0/0"]
    depends_on = [ google_compute_network.vpc_network ]
}

