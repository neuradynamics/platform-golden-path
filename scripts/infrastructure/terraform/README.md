# Simple Azure Kubernetes Service (AKS) Infrastructure

A minimal Terraform configuration for creating an Azure Kubernetes Service (AKS) cluster. 

## Features

- **AKS Cluster**: Single node cluster (can be scaled manually)
- **Networking**: Basic Virtual Network and Network Security Groups
- **Cost Optimized**: Uses Standard_B2s VM size (cheapest option)
- **Simple**: No auto-scaling, no complex monitoring, no additional services

## Prerequisites

1. **Azure CLI**: Install and authenticate with Azure
2. **Terraform**: Version 1.0 or higher
3. **Azure Subscription**: Active subscription
4. **Resource Group**: Existing resource group (specified in variables)

### Setup

```bash
# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Login to Azure
az login

# Install Terraform
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs)"
sudo apt-get update && sudo apt-get install terraform
```

## Quick Start

### 1. Create Resource Group

```bash
az group create --name "rg-klass-online-dev" --location "eastus"
```

### 2. Deploy Infrastructure

```bash
cd infrastructure/terraform

# Initialize Terraform
terraform init

# Plan deployment for development
terraform plan -var-file="environments/dev.tfvars" -out=dev.tfplan

# Apply the plan
terraform apply dev.tfplan
```

### 3. Get Cluster Credentials

```bash
# Get AKS credentials
az aks get-credentials --resource-group "rg-klass-online-dev" --name "klass-online-dev-aks"

# Verify connection
kubectl get nodes
```

## Configuration

### Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `resource_group_name` | Existing Azure resource group | Required |
| `aks_cluster_name` | Name of the AKS cluster | `my-aks-cluster` |
| `aks_dns_prefix` | DNS prefix for the cluster | `myakscluster` |
| `aks_node_count` | Number of nodes | `1` |
| `aks_vm_size` | VM size for nodes | `Standard_B2s` |

### Environment Files

- `environments/dev.tfvars` - Development environment (1 node)
- `environments/prod.tfvars` - Production environment (2 nodes)

## Manual Scaling

To add more nodes manually:

```bash
# Scale to 3 nodes
az aks scale --resource-group "rg-klass-online-dev" --name "klass-online-dev-aks" --node-count 3

# Scale back to 1 node
az aks scale --resource-group "rg-klass-online-dev" --name "klass-online-dev-aks" --node-count 1
```

## Deploy Your Application

```bash
# Build your Docker image
docker build -t your-app:latest .

# Deploy to Kubernetes
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml

# Check deployment
kubectl get pods
kubectl get services
```

## Clean Up

```bash
# Destroy the infrastructure
terraform destroy -var-file="environments/dev.tfvars"
```

## Troubleshooting

### Common Issues

1. **Resource Group Not Found**
   ```bash
   az group create --name "your-rg-name" --location "eastus"
   ```

2. **Insufficient Permissions**
   ```bash
   az role assignment list --assignee $(az account show --query user.name -o tsv)
   ```

3. **Cluster Connection Issues**
   ```bash
   az aks get-credentials --resource-group your-rg --name your-cluster --overwrite-existing
   ```

### Useful Commands

```bash
# Check cluster status
az aks show --resource-group your-rg --name your-cluster

# View cluster logs
az aks logs --resource-group your-rg --name your-cluster

# Get cluster credentials
az aks get-credentials --resource-group your-rg --name your-cluster
```

## Architecture

```
┌─────────────────────────────────────┐
│           AKS Cluster               │
├─────────────────────────────────────┤
│  ┌─────────────┐                    │
│  │   Node 1    │  (Standard_B2s)    │
│  │             │  - 2 vCPUs         │
│  │             │  - 4 GB RAM        │
│  └─────────────┘  - 8 GB Disk       │
└─────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────┐
│         Virtual Network             │
├─────────────────────────────────────┤
│  ┌─────────────┐                    │
│  │ AKS Subnet  │  10.0.1.0/24      │
│  └─────────────┘                    │
└─────────────────────────────────────┘
```

## Next Steps

1. **Add Ingress Controller**: Install NGINX Ingress for external access
2. **Set up Monitoring**: Add basic monitoring with Prometheus/Grafana
3. **Configure CI/CD**: Set up automated deployments
4. **Add Database**: Deploy PostgreSQL or use Azure Database services

## Support

For issues:
1. Check the troubleshooting section
2. Review Azure AKS documentation
3. Check Terraform documentation 