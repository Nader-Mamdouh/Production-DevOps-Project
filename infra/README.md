# Infrastructure Setup - AKS Cluster

This folder contains the **Terraform code** for provisioning an **Azure Kubernetes Service (AKS) cluster** along with supporting infrastructure. It is designed for **multi-environment setup** (dev, prod) and follows best practices for networking and cluster configuration.

---

## **Folder Structure**
```bash
infra/
├── modules/
│ └── aks/
│ ├── main.tf
│ ├── variables.tf
│ └── outputs.tf
├── env/
│ ├── dev/
│ │ ├── main.tf
│ │ ├── variables.tf
│ │ ├── providers.tf
│ │ └── terraform.tfvars
│ └── prod/
│   ├── main.tf
│   ├── providers.tf
│   ├── variables.tf
│   └── terraform.tfvars
```
- **modules/aks/**: Terraform module for creating AKS cluster, VNet, subnet, and node pools.  
- **env/dev/**: Dev environment configuration and variable values.  
- **env/prod/**: Prod environment configuration (optional; can scale resources differently).  

## **AKS Module Features**

- Creates **Resource Group**, **Virtual Network**, **Subnet**.  
- Creates an **AKS cluster** with:
  - System-assigned managed identity
  - Default node pool with configurable **node count** and **VM size**
  - Non-overlapping **service CIDR**, **DNS service IP**, **docker bridge**
- Multi-environment support via **Terraform workspaces** or separate `tfvars` files.  
- Ready for **Ingress controller deployment** and Helm charts.

## **Terraform Variables**

| Variable    |                   Description                    | Example |
|-------------|--------------------------------------------------|---------|
| `name`      | Resource prefix for cluster, VNet, RG            | `tactful-ai` |
| `location`  | Azure region (student subscription restrictions) | `uaenorth` |
| `node_count`| Number of nodes in default pool                  | `2` |
| `node_type` | VM size for nodes                                | `Standard_B2s`|

---
## **Getting Started**

### 1. Login to Azure

```bash
az login
az account set --subscription "Azure for Students"
```
### 2. Initialize Terraform
```bash
I will just deploy dev to reduce cost ;)
cd infra/env/dev
terraform init
```

### 3. Plan the deployment
```bash
terraform plan -var-file=terraform.tfvars
```

### 4. Apply the deployment
```bash
terraform apply -var-file=terraform.tfvars -auto-approve
```

**Expected time for dev cluster (2 nodes) is ~10–15 minutes.**

### 5. Configure kubectl
```bash
az aks get-credentials --resource-group tactful-ai-rg --name tactful-ai-aks
kubectl get nodes
```