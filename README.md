# GKE Monitoring Automation

The purpose of this repository is to automate the deployment of a fully managed **Prometheus + Grafana** monitoring stack on **Google Kubernetes Engine (GKE)** using **Terraform** and **Helm**.

> NOTE: This repository is intended for infrastructure automation and reproducibility.  
> It is not a support portal for Prometheus, Grafana, or GKE users.  
> Please refer to the Support section below for help resources.

---

## What is This Project?

This project provides a **standardized, production-ready approach** to deploying monitoring on GKE using Infrastructure-as-Code (IaC).

It performs all necessary actions to:
- Provision a GKE cluster with Terraform.
- Deploy Prometheus and Grafana using Helm.
- Configure service connections automatically (via LoadBalancer and Grafana datasources).

The scope of this project is limited to **GCP resources**, **Terraform state**, and **Kubernetes API interactions**.  
It is designed to be a **reusable automation module** or **building block** for larger cloud-native setups.

---

## ⚙️ Prerequisites

Before running the automation, ensure the following tools are installed and configured locally:

| Tool | Version | Description |
|------|----------|-------------|
| [Google Cloud SDK (`gcloud`)](https://cloud.google.com/sdk/docs/install) | Latest | Used for authentication and cluster management |
| [Terraform](https://developer.hashicorp.com/terraform/downloads) | ≥ 1.5.0 | Infrastructure provisioning |
| [**Helm ⚠️(must be installed locally)**](https://helm.sh/docs/intro/install/) | ≥ 3.12.0 | Required for deploying Prometheus and Grafana charts |
| [kubectl](https://kubernetes.io/docs/tasks/tools/) | Latest | Interacts with Kubernetes clusters |
| Bash Shell | — | Required to execute the automation script |

---

## Common Components and Commands

### Terraform
- `terraform init` – Initializes Terraform configuration and backend.
- `terraform plan` – Displays the planned infrastructure changes.
- `terraform apply -auto-approve` – Provisions the GKE cluster.
- `terraform destroy` – Tears down all created infrastructure.

### Script
- `bash deploy.sh`  #  STARTING POINT OF PROJECT 

### GCP Authentication
The project uses the **Service Account authentication method**.

export GOOGLE_APPLICATION_CREDENTIALS=~/gcp-key.json
