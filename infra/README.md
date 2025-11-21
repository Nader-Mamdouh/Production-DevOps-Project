# Infrastructure Setup - AKS Cluster

This folder contains the **Terraform code** for provisioning an **Azure Kubernetes Service (AKS) cluster** along with supporting infrastructure. It is designed for **multi-environment setup** (dev, prod) and follows best practices for networking and cluster configuration.

## Overview

The infrastructure is organized using Terraform modules and environment-specific configurations. This approach allows for:
- **Reusability**: The AKS module can be used across multiple environments
- **Isolation**: Separate configurations for dev and production
- **Maintainability**: Centralized module logic with environment-specific overrides
- **Scalability**: Easy to add new environments (staging, QA, etc.)

## Folder Structure

```
infra/
├── modules/
│   └── aks/                    # Reusable AKS module
│       ├── main.tf             # Main resource definitions
│       ├── variables.tf        # Module input variables
│       └── outputs.tf          # Module outputs
├── env/
│   ├── dev/                    # Development environment
│   │   ├── main.tf             # Module instantiation
│   │   ├── providers.tf        # Terraform provider configuration
│   │   ├── variables.tf        # Environment variables
│   │   ├── terraform.tfvars    # Variable values for dev
│   │   ├── terraform.tfstate   # Terraform state (gitignored in prod)
│   │   └── terraform.tfstate.backup
│   └── prod/                   # Production environment
│       ├── main.tf             # Module instantiation
│       ├── providers.tf        # Terraform provider configuration
│       ├── variables.tf        # Environment variables
│       └── terraform.tfvars    # Variable values for prod
└── README.md                   # This file
```

### Directory Descriptions

- **`modules/aks/`**: Reusable Terraform module that creates:
  - Azure Resource Group
  - Virtual Network (VNet) with address space `10.0.0.0/16`
  - Subnet for AKS nodes (`10.0.1.0/24`)
  - AKS cluster with system-assigned managed identity
  - Default node pool with configurable size and count

- **`env/dev/`**: Development environment configuration
  - Lower resource allocation for cost savings
  - Uses `Standard_B2s` VM size (2 vCPUs, 4GB RAM)
  - 2 nodes by default
  - Location: `uaenorth` (UAE North)

- **`env/prod/`**: Production environment configuration
  - Higher resource allocation for performance
  - Uses `Standard_D4ds_v5` VM size (4 vCPUs, 16GB RAM)
  - 3 nodes by default
  - Location: `East US`

## AKS Module Features

The AKS module creates a production-ready Kubernetes cluster with:

### Infrastructure Components

1. **Resource Group**: Container for all Azure resources
2. **Virtual Network**: Isolated network environment (`10.0.0.0/16`)
3. **Subnet**: Dedicated subnet for AKS nodes (`10.0.1.0/24`)
4. **AKS Cluster**: Managed Kubernetes service with:
   - System-assigned managed identity (no service principal needed)
   - Azure CNI networking plugin
   - Service CIDR: `10.2.0.0/16`
   - DNS Service IP: `10.2.0.10`
   - Default node pool named "system"

### Security Features

- **Managed Identity**: System-assigned identity for secure Azure resource access
- **Network Isolation**: VNet integration for network security
- **RBAC**: Kubernetes RBAC enabled by default

### Networking Configuration

- **Network Plugin**: Azure CNI (Container Networking Interface)
- **Service CIDR**: `10.2.0.0/16` (non-overlapping with node subnet)
- **DNS Service IP**: `10.2.0.10` (within service CIDR)
- **Subnet Integration**: Nodes deployed in dedicated subnet

## Terraform Variables

### Module Variables (`modules/aks/variables.tf`)

| Variable | Type | Description | Default | Example |
|----------|------|-------------|---------|---------|
| `name` | `string` | Resource prefix for cluster, VNet, and Resource Group | - | `tactful-ai` |
| `location` | `string` | Azure region for all resources | - | `uaenorth`, `eastus` |
| `node_count` | `number` | Number of nodes in default node pool | `1` | `2`, `3` |
| `node_type` | `string` | Azure VM size for nodes | `Standard_B2s` | `Standard_B2s`, `Standard_D4ds_v5` |

### Environment Variables (`env/*/variables.tf`)

Each environment defines the same variables that are passed to the module:
- `name`: Environment-specific name prefix
- `location`: Azure region for the environment
- `node_count`: Number of nodes
- `node_type`: VM size

## Environment Configurations

### Development Environment (`env/dev/`)

**Configuration:**
```hcl
name       = "tactful-ai"
location   = "uaenorth"
node_count = 2
node_type  = "Standard_B2s"
```

**Characteristics:**
- **Cost-optimized**: Smaller VM size and fewer nodes
- **Suitable for**: Development, testing, learning
- **Estimated cost**: Lower (varies by region and usage)
- **Performance**: Adequate for development workloads

### Production Environment (`env/prod/`)

**Configuration:**
```hcl
location   = "East US"
node_count = 3
node_type  = "Standard_D4ds_v5"
```

**Characteristics:**
- **Performance-optimized**: Larger VM size and more nodes
- **Suitable for**: Production workloads, high availability
- **Estimated cost**: Higher (varies by region and usage)
- **Performance**: Better CPU and memory for production apps

## Module Outputs

The AKS module provides the following outputs (`modules/aks/outputs.tf`):

| Output | Description |
|--------|-------------|
| `resource_group_name` | Name of the created resource group |
| `aks_cluster_name` | Name of the AKS cluster |
| `kube_config` | Raw kubeconfig for cluster access |

**Usage:**
```hcl
# Access outputs in environment configuration
output "cluster_name" {
  value = module.aks.aks_cluster_name
}
```

## Prerequisites

Before deploying, ensure you have:

1. **Azure CLI** installed and configured
   ```bash
   az --version
   ```

2. **Terraform** installed (v1.0+)
   ```bash
   terraform version
   ```

3. **kubectl** installed (for cluster interaction)
   ```bash
   kubectl version --client
   ```

4. **Azure Subscription** with appropriate permissions:
   - Contributor or Owner role
   - Ability to create Resource Groups, VNets, and AKS clusters

5. **Azure Account** logged in
   ```bash
   az login
   az account show
   ```

## Getting Started

### 1. Login to Azure

```bash
# Login to Azure
az login

# Set the correct subscription (if you have multiple)
az account list --output table
az account set --subscription "Azure for Students"  # or your subscription name
```

### 2. Navigate to Environment Directory

```bash
# For development environment
cd infra/env/dev

# For production environment
cd infra/env/prod
```

### 3. Initialize Terraform

```bash
# Initialize Terraform and download providers
terraform init
```

This will:
- Download the Azure provider
- Initialize the backend (local state by default)
- Set up the module references

### 4. Review the Plan

```bash
# Review what will be created (without applying)
terraform plan -var-file=terraform.tfvars
```

**Important**: Review the plan carefully to ensure:
- Correct resource names
- Appropriate VM sizes
- Correct node counts
- Correct Azure region

### 5. Apply the Infrastructure

```bash
# Apply the configuration (creates resources)
terraform apply -var-file=terraform.tfvars

# Or use auto-approve to skip confirmation (use with caution)
terraform apply -var-file=terraform.tfvars -auto-approve
```

**Expected Deployment Time:**
- Dev cluster (2 nodes): ~10-15 minutes
- Prod cluster (3 nodes): ~15-20 minutes

### 6. Configure kubectl

After the cluster is created, configure kubectl to connect:

```bash
# Get credentials for the cluster
az aks get-credentials \
  --resource-group <resource-group-name> \
  --name <cluster-name>

# For dev environment:
az aks get-credentials \
  --resource-group tactful-ai-rg \
  --name tactful-ai-aks

# Verify connection
kubectl get nodes
kubectl get namespaces
```

## Managing Infrastructure

### View Current State

```bash
# Show current state
terraform show

# List all resources
terraform state list
```

### Modify Configuration

1. Update `terraform.tfvars` or variables
2. Review changes:
   ```bash
   terraform plan -var-file=terraform.tfvars
   ```
3. Apply changes:
   ```bash
   terraform apply -var-file=terraform.tfvars
   ```

### Scale Node Count

```bash
# Update node_count in terraform.tfvars
# Then apply
terraform apply -var-file=terraform.tfvars
```

### Change VM Size

**Note**: Changing VM size may require node pool recreation, which can cause downtime.

```bash
# Update node_type in terraform.tfvars
# Then apply
terraform plan -var-file=terraform.tfvars  # Review impact
terraform apply -var-file=terraform.tfvars
```

### Destroy Infrastructure

**⚠️ WARNING**: This will delete all resources including persistent data!

```bash
# Review what will be destroyed
terraform plan -destroy -var-file=terraform.tfvars

# Destroy infrastructure
terraform destroy -var-file=terraform.tfvars
```

## Post-Deployment Steps

### 1. Install NGINX Ingress Controller

```bash
# Add NGINX Ingress Helm repository
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Install NGINX Ingress Controller
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace
```

### 2. Verify Cluster Access

```bash
# Check nodes
kubectl get nodes -o wide

# Check system pods
kubectl get pods -n kube-system

# Check cluster info
kubectl cluster-info
```

### 3. Deploy Application

After the cluster is ready, deploy your application using:
- Kubernetes manifests from `K8s/` folder, or
- Helm charts from `helm/` folder

## Troubleshooting

### Common Issues

#### Issue: Terraform init fails

**Solution:**
```bash
# Clear Terraform cache
rm -rf .terraform
terraform init
```

#### Issue: Authentication errors

**Solution:**
```bash
# Re-authenticate with Azure
az login
az account set --subscription "Your Subscription Name"
```

#### Issue: Insufficient permissions

**Error**: `Authorization failed`

**Solution**: Ensure your Azure account has Contributor or Owner role on the subscription.

#### Issue: Quota exceeded

**Error**: `Operation could not be completed as it results in exceeding approved quota`

**Solution**:
- Check Azure subscription quotas
- Reduce node count or use smaller VM size
- Request quota increase from Azure support

#### Issue: Region not available

**Error**: `The location is not available for subscription`

**Solution**: Choose a different Azure region in `terraform.tfvars`.

#### Issue: kubectl connection fails

**Solution:**
```bash
# Refresh credentials
az aks get-credentials --resource-group <rg-name> --name <cluster-name> --overwrite-existing

# Check cluster status
az aks show --resource-group <rg-name> --name <cluster-name> --query "powerState.code"
```

### Debugging Terraform

```bash
# Enable verbose logging
export TF_LOG=DEBUG
terraform apply -var-file=terraform.tfvars

# Check Terraform version compatibility
terraform version
```

### Getting Help

```bash
# View Terraform help
terraform -help

# View Azure CLI help
az aks --help

# Check Azure service health
az monitor metrics list-definitions --resource <resource-id>
```

## Best Practices

1. **State Management**: Use remote state (Azure Storage, Terraform Cloud) for production
2. **Version Control**: Never commit `terraform.tfstate` files with sensitive data
3. **Tagging**: Add tags to resources for cost tracking and organization
4. **Backup**: Regularly backup Terraform state files
5. **Review Plans**: Always review `terraform plan` before applying
6. **Environment Isolation**: Use separate subscriptions or resource groups for dev/prod
7. **Resource Naming**: Use consistent naming conventions
8. **Cost Monitoring**: Monitor Azure costs regularly
9. **Security**: Use managed identities instead of service principals
10. **Documentation**: Keep this README updated with environment-specific notes

## Cost Considerations

### Development Environment
- **VM Size**: `Standard_B2s` (2 vCPU, 4GB RAM)
- **Nodes**: 2
- **Estimated Monthly Cost**: ~$50-100 USD (varies by region and usage)
- **Tips**: Stop the cluster when not in use to save costs

### Production Environment
- **VM Size**: `Standard_D4ds_v5` (4 vCPU, 16GB RAM)
- **Nodes**: 3
- **Estimated Monthly Cost**: ~$300-500 USD (varies by region and usage)
- **Tips**: Use Azure Reserved Instances for long-term cost savings

**Note**: Costs vary significantly by:
- Azure region
- VM size and count
- Data transfer
- Storage usage
- Additional services (Load Balancer, etc.)

## Security Considerations

1. **Network Security**: VNet integration provides network isolation
2. **Identity**: System-assigned managed identity is more secure than service principals
3. **RBAC**: Kubernetes RBAC should be configured for cluster access
4. **Secrets**: Never commit secrets or credentials to version control
5. **Updates**: Keep AKS cluster and node images updated
6. **Monitoring**: Enable Azure Monitor and Log Analytics for security auditing

## Additional Resources

- [Terraform Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [AKS Documentation](https://docs.microsoft.com/azure/aks/)
- [Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)