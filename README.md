# 🧠 GKE Monitoring Stack — Terraform + Prometheus + Grafana

This project deploys a **lightweight, production-grade monitoring stack** on **Google Kubernetes Engine (GKE)** using **Terraform** for infrastructure provisioning and **Kubernetes manifests** for Prometheus and Grafana deployment.

---

## 🚀 Architecture Overview

```text
Terraform
    ↓
GCP Resources (VPC, Subnet, Firewall, GKE, NodePool)
    ↓
Kubernetes Cluster
    ↓
Monitoring Applications (Prometheus + Grafana)
    ↓
External Access via LoadBalancer

⚙️ Prerequisites
Google Cloud SDK
Terraform ≥ 1.0
kubectl
GCP Project with GKE API enabled
IAM roles:
roles/container.admin
roles/compute.admin
roles/storage.admin

🧰 Features
✅ VPC, Subnet, Firewall, GKE via Terraform
✅ Prometheus & Grafana deployed on Kubernetes
✅ External access with LoadBalancer
✅ IaC automation & easy re-deploy
✅ One command setup via deploy.sh


📈 Future Enhancements
Add Alertmanager integration
Configure Persistent Volumes for Prometheus
Automate Grafana dashboards import
Add ServiceMonitor & PodMonitor (for app-level metrics)

🧑‍💻 Author
Chahat Yadav
