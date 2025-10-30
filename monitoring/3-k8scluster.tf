
resource "google_container_cluster" "primary" {
  name     = "my-gke-cluster"
  location = "us-central1"
  remove_default_node_pool = true
  initial_node_count       = 1
    ip_allocation_policy {
    cluster_secondary_range_name  = "nodes"      
    services_secondary_range_name = "services"  
  }
  depends_on = [ google_compute_network.vpc_network ]
}

resource "google_container_node_pool" "primary_preemptible_nodes" {
  name       = "my-node-pool"
  location   = "us-central1"
  cluster    = google_container_cluster.primary.name
  node_count = 1
  node_config {
    preemptible  = true
    machine_type = "e2-medium"
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = var.service_account

    oauth_scopes    = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
  depends_on = [ google_container_cluster.primary ]
}