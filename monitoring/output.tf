output "cluster_name" {
  description = "GKE Cluster Name"
  value       = google_container_cluster.primary.name
}

output "cluster_region" {
  description = "GKE Cluster Region"
  value       = var.region
}

output "project_id" {
  description = "GCP Project ID"
  value       = var.project_id
}

output "access_instructions" {
  description = "Instructions to access the monitoring stack"
  value       = <<EOT

=== Monitoring Stack Access ===

1. Get cluster credentials:
   gcloud container clusters get-credentials ${google_container_cluster.primary.name} --region ${var.region} --project ${var.project_id}

2. Deploy monitoring applications:
   kubectl apply -f kubernetes/

3. Access via port-forwarding:
   Grafana:     kubectl port-forward -n monitoring service/grafana 3000:3000
   Prometheus:  kubectl port-forward -n monitoring service/prometheus 9090:9090

4. Access via LoadBalancer IPs:
   kubectl get services -n monitoring -o wide

EOT
}