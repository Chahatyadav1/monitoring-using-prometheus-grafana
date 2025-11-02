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
success=false
for i in {1..10}; do
    if terraform apply -auto-approve &>/dev/null; then
        echo " Terraform apply successful"
        success=true
        break
    else
        echo " Waiting for Terraform apply to complete... retry ($i/10)"
        sleep 30s
    fi
done
if [ "$success" = false ]; then
    echo " Terraform apply failed after 10 retries"
    exit 1
fi

PROJECT_ID=$(terraform output -raw project_id)
REGION=$(terraform output -raw cluster_region)
CLUSTER_NAME=$(terraform output -raw cluster_name)

echo " Getting GKE cluster credentials..."
if ! gcloud container clusters get-credentials "$CLUSTER_NAME" --region "$REGION" --project "$PROJECT_ID" &>/dev/null; then
    echo " Failed to configure GKE cluster credentials"
    exit 1
else
    echo " GKE cluster credentials configured successfully"
fi

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
if ! helm repo update &>/dev/null; then
    echo " Helm repo update failed"
    exit 1
fi


#  -------- Deploy Prometheus ---------

echo " Deploying Prometheus..."
success=false
for i in {1..4}; do
    if helm upgrade --install my-prometheus prometheus-community/prometheus --namespace monitoring --create-namespace --set alertmanager.enabled=false  --set server.service.type=LoadBalancer &>/dev/null; then
        echo " Prometheus Helm chart deployed successfully"
        success=true
        break
    else
        echo " Retrying Prometheus deployment... ($i/4)"
        sleep 20s
    fi
done
if [ "$success" = false ]; then
    echo " Prometheus deployment failed after 4 retries"
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
if [ -z "$prometheus_ip" ]; then
    echo " Prometheus LoadBalancer IP not assigned after waiting."
    exit 1
fi


# --------  Deploy Grafana ------------

echo " Deploying Grafana..."
success=false
for i in {1..4}; do
    if helm upgrade --install grafana grafana/grafana \
        --namespace monitoring \
        --set service.type=LoadBalancer &>/dev/null; then
        echo " Grafana Helm chart deployed successfully"
        success=true
        break
    else
        echo " Retrying Grafana deployment... ($i/4)"
        sleep 20s
    fi
done
if [ "$success" = false ]; then
    echo " Grafana deployment failed after 4 retries"
    exit 1
fi

echo "⏳ Waiting for Grafana LoadBalancer IP..."
for i in {1..20}; do
    grafana_ip=$(kubectl get svc --namespace monitoring grafana -o jsonpath="{.status.loadBalancer.ingress[0].ip}")
    if [ -n "$grafana_ip" ]; then
        echo " Grafana available at: http://$grafana_ip:80"
        break
    fi
    echo " Still waiting for Grafana IP... ($i/20)"
    sleep 15s
done
if [ -z "$grafana_ip" ]; then
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
