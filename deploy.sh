#!/bin/bash
set -e
cd monitoring

echo "initilizing terraform" 
if ! terraform init &>/dev/null ; then
    echo "terraform init failed"
    exit 1
fi
echo "applying terraform"
for i in {1..10} ;do
    if  terraform apply -auto-approve &>/dev/null ;then
        echo " terraform apply sucessfully"
        break
    else 
        echo " waiting for applying ..., retrying in 30 seconds {$i}/10"
        sleep 30s
    fi
done
PROJECT_ID=$(terraform output -raw project_id)
REGION=$(terraform output -raw cluster_region)
CLUSTER_NAME=$(terraform output -raw cluster_name)

echo " Getting gke cluster credentials"
if ! gcloud container clusters get-credentials "$CLUSTER_NAME" --region "$REGION" --project "$PROJECT_ID" &>/dev/null ; then
    echo " cluster not configured yet "
    exit 1
else 
    echo " gke cluster credentials configured"
fi
echo " adding helm repos"
if ! helm repo add prometheus-community https://prometheus-community.github.io/helm-charts &>/dev/null ; then
    echo " adding prometheus helm repo failed"
    exit 1
fi
if ! helm repo add grafana https://grafana.github.io/helm-charts &>/dev/null ; then
    echo " adding grafana helm repo failed"
    exit 1
fi
echo " updating helm repos"
if ! helm repo update &>/dev/null ; then
    echo " helm repo update failed"
    exit 1
fi
echo " deploy prometheus chart"
for i in {1..10} ;do
    if  helm install my-prometheus prometheus-community/prometheus --namespace monitoring --create-namespace --set alertmanager.enabled=false --set server.service.type=LoadBalancer &>/dev/null ; then
        echo " prometheus helm chart deployment sucessfully"
        break
    else 
        echo " Wait for prometheus server loadbalancer ip..., {$i}/10"
        sleep 15s
    fi
done
$prometheus_ip=$(kubectl get svc --namespace monitoring my-prometheus-server -o jsonpath="{.status.loadBalancer.ingress[0].ip}")
echo " Prometheus Server is available at http://$prometheus_ip:80"
echo " deploy grafana chart"
for i in {1..10} ;do
    if  helm install grafana grafana/grafana --namespace monitoring --set server.service.type=LoadBalancer &>/dev/null ; then
        echo " grafana helm chart deployment sucessfully"
        break
    else 
        echo "Wait for grafana server loadbalancer ip..., {$i}/10"
        sleep 15s
    fi
done    
$grafana_ip=$(kubectl get svc --namespace monitoring grafana -o jsonpath="{.status.loadBalancer.ingress[0].ip}")
echo " Grafana is available at http://$grafana_ip:80"

GRAFANA_PASSWORD=$(kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode)

echo " monitoring stack deploy completed successfully "

