#!/bin/bash
set -e

# =====  COLOR CODES =====
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# =====  INPUT CHECK =====
PROJECT_ID="$1"
REGION="$2"

if [ -z "$PROJECT_ID" ] || [ -z "$REGION" ]; then
  echo -e "${YELLOW}Example:${NC} $0 kubernetesmonitoringprometheus us-central1"
  exit 1
fi

echo -e "${YELLOW}🚀 Deploying monitoring stack to project:${NC} $PROJECT_ID in region: $REGION"

BUCKET_NAME="${PROJECT_ID}-tf-state-monitoring"

# ===== CREATE GCS BUCKET =====
if ! gsutil ls -b "gs://${BUCKET_NAME}" >/dev/null 2>&1; then
  echo -e "${YELLOW}Creating backend bucket:${NC} $BUCKET_NAME"
  gsutil mb "gs://${BUCKET_NAME}"
  gsutil versioning set on "gs://${BUCKET_NAME}"
else
  echo -e "${GREEN}✔️ GCS bucket already exists:${NC} $BUCKET_NAME"
fi

# =====  DEPLOY TERRAFORM STRUCTURE =====
echo -e "${YELLOW}Deploying GCP structure using Terraform...${NC}"
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

# =====  CONFIGURE CLUSTER ACCESS =====
echo -e "${YELLOW}Fetching Kubernetes credentials from GKE...${NC}"
gcloud container clusters get-credentials "$(terraform output -raw cluster_name)" --region "$REGION" --project "$PROJECT_ID"

# =====  CHECK DEPENDENCIES =====
if ! command -v helm &>/dev/null; then
  echo -e "${RED} Helm not found. Please install Helm first.${NC}"
  exit 1
fi

if ! command -v kubectl &>/dev/null; then
  echo -e "${RED} kubectl not found. Please install kubectl first.${NC}"
  exit 1
fi

# =====  ADD HELM REPOSITORIES =====
echo -e "${YELLOW} Adding Helm repositories...${NC}"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts

# =====  UPDATE HELM REPOSITORIES =====
echo -e "${YELLOW} Updating Helm repositories...${NC}"
helm repo update

# =====  WAIT BEFORE INSTALL =====
echo -e "${GREEN} Helm repositories updated.${NC}"
echo -e "${YELLOW} Waiting for 5 seconds before installation...${NC}"
sleep 5
# Uncomment the below line if you prefer manual confirmation
# read -p "Press Enter to continue with installation..."

# =====  CREATE NAMESPACE =====
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
echo -e "${GREEN} Namespace 'monitoring' ready.${NC}"

# =====  INSTALL PROMETHEUS STACK =====
echo -e "${YELLOW} Installing kube-prometheus-stack...${NC}"
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack -n monitoring

# =====  DONE =====
echo -e "${GREEN} Prometheus Stack installation complete!${NC}"
echo -e "${YELLOW}Use the following commands to verify:${NC}"
echo -e "  ${GREEN}kubectl get pods -n monitoring${NC}"
echo -e "  ${GREEN}kubectl port-forward svc/kube-prometheus-stack-prometheus -n monitoring 9090:9090${NC}"
echo -e "  ${GREEN}kubectl port-forward svc/kube-prometheus-stack-grafana -n monitoring 3000:80${NC}"
