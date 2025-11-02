#!/bin/bash
set -e

# go to monitoring folder
cd monitoring || { echo " monitoring directory not found"; exit 1; }

echo " Initializing Terraform..."
if ! terraform init &>/dev/null; then
    echo " Terraform init failed"
    exit 1
fi

echo " Applying Terraform..."
if ! terraform apply -auto-approve -input=false; then
  echo " Terraform apply failed."
  terraform show                                             #  for debugging
  exit 1
fi

PROJECT_ID=$(terraform output -raw project_id)
REGION=$(terraform output -raw cluster_region)
CLUSTER_NAME=$(terraform output -raw cluster_name)

echo " Getting GKE cluster credentials..."
echo " Waiting for GKE cluster credentials to become available..."
success=false
for i in {1..5}; do
    if gcloud container clusters get-credentials "$CLUSTER_NAME" \
        --region "$REGION" \
        --project "$PROJECT_ID" &>/dev/null; then
        echo " GKE cluster credentials configured successfully"
        success=true
        break
    else
        echo " Cluster not ready yet... retrying in 20s ($i/5)"
        sleep 20
    fi
done

if [ "$success" != true ]; then
    echo "Failed to configure GKE cluster credentials after multiple attempts"
    exit 1
fi
echo "download helm"
echo " Adding Helm repositories..."
if ! helm repo add prometheus-community https://prometheus-community.github.io/helm-charts &>/dev/null; then
    echo "Adding Prometheus Helm repo failed"
    exit 1
fi
if ! helm repo add grafana https://grafana.github.io/helm-charts &>/dev/null; then
    echo " Adding Grafana Helm repo failed"
    exit 1
fi

echo " Updating Helm repositories..."
if  helm repo update &>/dev/null; then
    echo " Helm repo update sucess"
else
    echo " Helm repo update failed"     
    exit 1
fi


#  -------- Deploy Prometheus ---------
echo " Deploying Prometheus..."

if helm upgrade --install my-prometheus prometheus-community/prometheus \
    --namespace monitoring \
    --create-namespace \
    --set alertmanager.enabled=false \
    --set server.service.type=LoadBalancer \
    --wait --timeout 10m &>/dev/null; then

    echo " Prometheus Helm chart deployed successfully."

else
    echo " Prometheus deployment failed. Check 'kubectl get pods -n monitoring' for details."
    exit 1
fi
echo " Waiting for Prometheus LoadBalancer IP..."
for i in {1..20}; do
    prometheus_ip=$(kubectl get svc --namespace monitoring my-prometheus-server -o jsonpath="{.status.loadBalancer.ingress[0].ip}")
    if [ -n "$prometheus_ip" ]; then
        echo " Prometheus Server available at: http://$prometheus_ip:80"
        break
    fi
    echo " Still waiting for Prometheus IP... ($i/20)"
    sleep 15s
done
if [[ -z "$prometheus_ip" ]]; then
    echo " Prometheus LoadBalancer IP not assigned after waiting."
    exit 1
fi


# --------  Deploy Grafana ------------

echo " Deploying Grafana..."
if helm upgrade --install grafana grafana/grafana \
    --namespace monitoring \
    --create-namespace \
    --set service.type=LoadBalancer \
    --wait --timeout 10m &>/dev/null; then

    echo " Grafana Helm chart deployed successfully."
else
    echo " Grafana deployment failed. Check 'kubectl get pods -n monitoring' for more details."
    exit 1
fi

echo " Waiting for Grafana LoadBalancer IP..."
for i in {1..20}; do
    grafana_ip=$(kubectl get svc --namespace monitoring grafana -o jsonpath="{.status.loadBalancer.ingress[0].ip}")
    if [ -n "$grafana_ip" ]; then
        echo " Grafana available at: http://$grafana_ip:80"
        break
    fi
    echo " Still waiting for Grafana IP... ($i/20)"
    sleep 15s
done
if [[ -z "$grafana_ip" ]]; then
    echo " Grafana LoadBalancer IP not assigned after waiting."
    exit 1
fi

echo " Monitoring stack deployed successfully!"


GRAFANA_PASSWORD=$(kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode)

cd ../kuberneties || { echo " kuberneties directory not found"; exit 1; }   # go to kuberneties folder

echo "Applying Grafana datasource configuration..."
if kubectl apply -f datasource.yaml &>/dev/null; then
    echo " Grafana datasource ConfigMap applied successfully"
else
    echo " Failed to apply Grafana datasource config"
    exit 1
fi

echo "Grafana dashboard configured successfully!"

echo ""
echo " Access details:"
echo "────────────────────────────"
echo " Prometheus: http://$prometheus_ip:80"
echo " Grafana:    http://$grafana_ip:80"
echo " Username:   admin"
echo " Password:   $GRAFANA_PASSWORD"
echo "────────────────────────────"
