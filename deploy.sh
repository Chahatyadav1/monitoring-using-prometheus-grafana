#!/bin/bash
set -e
PROJECT_ID="$1"
REGION="$2"
if [ -z "$PROJECT_ID" ] || [ -z "$REGION" ]; then
  echo "Usage: $0  kubernetesmonitoringprometheus  us-central1"
  exit 1
fi
echo "Deploying monitoring stack to project: $PROJECT_ID in region: $REGION"

BUCKET_NAME="${PROJECT_ID}-tf-state-monitoring"
if !gsutil ls -b "gs://${BUCKET_NAME}" 2>/dev/null; then
echo "Creating backend bucket: $BUCKET_NAME"
gsutil mb "gs://${BUCKET_NAME}"
gsutil versoning set on "gs://${BUCKET_NAME}"
fi

echo "Deploying GCP structure using Terraform..."
cd monitoring
cat > backend.tf <<EOF
terraform {
  backend "gcs" {
    bucket = "${BUCKET_NAME}"
    prefix = "terraform/state/monitoring"
  }
}
EOF
terraform init
terraform apply -auto-approve

gcloud container clusters get-credentials $(terraform output -raw cluster_name) --region $REGION --project $PROJECT_ID
# Deploy Kubernetes applications
echo "⚙️  Deploying monitoring applications to Kubernetes..."
cd ../kubernetes

echo "Creating monitoring namespace..."
kubectl apply -f monitoring-namespace.yaml

echo "Deploying Prometheus..."
kubectl apply -f prometheus-deployment.yaml

echo "Deploying Grafana..."
kubectl apply -f grafana-deployment.yaml

echo "Deploying Services..."
kubectl apply -f services.yaml