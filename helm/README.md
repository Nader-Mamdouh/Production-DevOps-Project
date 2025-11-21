# Helm Charts

This directory contains Helm charts for deploying the Dogs vs Cats voting application on Kubernetes. Helm provides a package management system for Kubernetes that simplifies deployment, configuration management, and versioning of applications.

## Overview

Helm charts are templated Kubernetes manifests that allow for parameterized deployments. Each chart in this directory corresponds to a component of the voting application and can be customized through `values.yaml` files.

## Directory Structure

```
helm/
├── db-chart/          # PostgreSQL database chart
├── redis-chart/       # Redis cache chart
├── vote-chart/        # Voting frontend chart
├── result-chart/      # Results display frontend chart
└── worker-chart/      # Background worker chart
```

Each chart follows the standard Helm chart structure:
```
<chart-name>/
├── Chart.yaml         # Chart metadata and version information
├── values.yaml        # Default configuration values
└── templates/         # Kubernetes manifest templates
    ├── _helpers.tpl   # Template helper functions
    ├── Deployment.yaml / Statefulset.yaml
    ├── Service.yaml
    ├── Configmap.yaml (if applicable)
    ├── Secret.yaml (if applicable)
    ├── PVC.yaml (if applicable)
    ├── NetworkPolicy.yaml (network isolation)
    └── Ingress.yaml (if applicable)
```

## Charts

### 1. Database Chart (`db-chart/`)

Helm chart for deploying PostgreSQL 15 database as a StatefulSet.

**Components:**
- StatefulSet for PostgreSQL with persistent storage
- Service (ClusterIP) exposing PostgreSQL on port 5432
- Secret for database credentials
- ConfigMap for PostgreSQL configuration
- PersistentVolumeClaim for 10Gi storage
- NetworkPolicy for database isolation

**Key Configuration (values.yaml):**
- Namespace: `db`
- Image: `postgres:15-alpine`
- Replicas: 1
- Storage: 10Gi
- Resource limits: 256Mi-512Mi memory, 250m-1000m CPU
- PostgreSQL configuration: shared_buffers, work_mem, WAL settings

**Customization:**
```yaml
postgres:
  replicas: 1
  postgres:
    image:
      repository: postgres
      tag: 15-alpine
    resources:
      limits:
        cpu: "1"
        memory: 512Mi
      requests:
        cpu: 250m
        memory: 256Mi
  volumeClaims:
    postgresData:
      requests:
        storage: 10Gi
```

### 2. Redis Chart (`redis-chart/`)

Helm chart for deploying Redis 7 cache as a StatefulSet.

**Components:**
- StatefulSet for Redis with persistent storage
- Service (ClusterIP) exposing Redis on port 6379
- ConfigMap for Redis configuration
- PersistentVolumeClaim for 8Gi storage

**Key Configuration (values.yaml):**
- Namespace: `cache`
- Image: `redis:7-alpine`
- Replicas: 1
- Storage: 8Gi
- Resource limits: 128Mi-256Mi memory, 100m-500m CPU
- Redis configuration: maxmemory 256mb, eviction policy allkeys-lru

**Customization:**
```yaml
redis:
  replicas: 1
  redis:
    image:
      repository: redis
      tag: 7-alpine
    resources:
      limits:
        cpu: 500m
        memory: 256Mi
      requests:
        cpu: 100m
        memory: 128Mi
  volumeClaims:
    redisData:
      requests:
        storage: 8Gi
```

### 3. Vote Chart (`vote-chart/`)

Helm chart for deploying the voting frontend application.

**Components:**
- Deployment with configurable replicas
- Service (NodePort) on port 8080
- Ingress for external access

**Key Configuration (values.yaml):**
- Namespace: `frontend`
- Image: `nadermamdouh869/vote:v1`
- Replicas: 1 (default, can be scaled)
- Resource limits: 100Mi-128Mi memory, 100m-500m CPU
- Connects to Redis for vote storage

**Customization:**
```yaml
deployment:
  replicas: 1
  voteContainer:
    image:
      repository: nadermamdouh869/vote
      tag: v1
    env:
      redisHost: redis.cache.svc.cluster.local
      redisPort: "6379"
      redisPassword: ""
    resources:
      limits:
        cpu: 500m
        memory: 128Mi
      requests:
        cpu: 100m
        memory: 100Mi
```

### 4. Result Chart (`result-chart/`)

Helm chart for deploying the results display frontend application.

**Components:**
- Deployment with configurable replicas
- Service (NodePort) on port 8081
- Ingress for external access

**Key Configuration (values.yaml):**
- Namespace: `frontend`
- Image: `nadermamdouh869/result:v3`
- Replicas: 2 (default)
- Resource limits: 100Mi-128Mi memory, 100m-500m CPU
- Connects to PostgreSQL for reading results

**Customization:**
```yaml
deployment:
  replicas: 2
  resultContainer:
    image:
      repository: nadermamdouh869/result
      tag: v3
    env:
      dbHost: postgres-db.db.svc.cluster.local
      dbPort: "5432"
      dbName: postgres
    resources:
      limits:
        cpu: 500m
        memory: 128Mi
      requests:
        cpu: 100m
        memory: 100Mi
```

### 5. Worker Chart (`worker-chart/`)

Helm chart for deploying the background worker service.

**Components:**
- Deployment with configurable replicas

**Key Configuration (values.yaml):**
- Namespace: `backend`
- Image: `nadermamdouh869/worker:v3`
- Replicas: 1 (default)
- Resource limits: 100Mi-128Mi memory, 100m-500m CPU
- Connects to both Redis (reads votes) and PostgreSQL (writes results)

**Customization:**
```yaml
workerDeployment:
  replicas: 1
  workerContainer:
    image:
      repository: nadermamdouh869/worker
      tag: v3
    env:
      redisHost: redis.cache.svc.cluster.local
      redisPort: "6379"
      redisPassword: ""
      dbHost: postgres-db.db.svc.cluster.local
      dbPort: "5432"
      dbName: postgres
    resources:
      limits:
        cpu: 500m
        memory: 128Mi
      requests:
        cpu: 100m
        memory: 100Mi
```

## Prerequisites

- Kubernetes cluster (v1.20+)
- Helm 3.x installed
- kubectl configured to access your cluster
- NGINX Ingress Controller (for Ingress resources)
- Storage class configured for PersistentVolumeClaims

## Installation

### Install All Charts

Deploy charts in the following order to ensure dependencies are met:

```bash
# 1. Install database chart
helm install db ./db-chart -n db --create-namespace

# 2. Install Redis chart
helm install redis ./redis-chart -n cache --create-namespace

# 3. Install worker chart (depends on db and redis)
helm install worker ./worker-chart -n backend --create-namespace

# 4. Install vote chart (depends on redis)
helm install vote ./vote-chart -n frontend --create-namespace

# 5. Install result chart (depends on db)
helm install result ./result-chart -n frontend --create-namespace
```

### Install with Custom Values

You can override default values using a custom values file or command-line flags:

```bash
# Using a custom values file
helm install db ./db-chart -f custom-db-values.yaml -n db --create-namespace

# Using command-line flags
helm install db ./db-chart \
  --set postgres.replicas=2 \
  --set postgres.postgres.resources.limits.memory=1Gi \
  -n db --create-namespace
```

### Upgrade Existing Releases

```bash
# Upgrade with new values
helm upgrade db ./db-chart -f custom-db-values.yaml -n db

# Upgrade with new chart version
helm upgrade db ./db-chart --version 0.2.0 -n db
```

## Configuration

### Common Customizations

#### Scaling Replicas

```bash
# Scale vote service
helm upgrade vote ./vote-chart \
  --set deployment.replicas=3 \
  -n frontend

# Scale result service
helm upgrade result ./result-chart \
  --set deployment.replicas=3 \
  -n frontend

# Scale worker service
helm upgrade worker ./worker-chart \
  --set workerDeployment.replicas=3 \
  -n backend
```

#### Update Container Images

```bash
# Update vote image
helm upgrade vote ./vote-chart \
  --set deployment.voteContainer.image.tag=v2 \
  -n frontend

# Update result image
helm upgrade result ./result-chart \
  --set deployment.resultContainer.image.tag=v4 \
  -n frontend
```

#### Modify Resource Limits

```bash
# Increase database resources
helm upgrade db ./db-chart \
  --set postgres.postgres.resources.limits.memory=1Gi \
  --set postgres.postgres.resources.limits.cpu="2" \
  -n db
```

#### Change Storage Size

```bash
# Increase PostgreSQL storage
helm upgrade db ./db-chart \
  --set postgres.volumeClaims.postgresData.requests.storage=20Gi \
  -n db

# Increase Redis storage
helm upgrade redis ./redis-chart \
  --set redis.volumeClaims.redisData.requests.storage=16Gi \
  -n cache
```

## Management

### List Installed Releases

```bash
# List all releases
helm list --all-namespaces

# List releases in a specific namespace
helm list -n frontend
```

### View Release Status

```bash
# Get release status
helm status db -n db

# Get release values
helm get values db -n db

# Get all release information
helm get all db -n db
```

### Rollback Releases

```bash
# View release history
helm history db -n db

# Rollback to previous version
helm rollback db -n db

# Rollback to specific revision
helm rollback db 2 -n db
```

### Uninstall Releases

```bash
# Uninstall a release
helm uninstall db -n db

# Uninstall all releases
helm uninstall db -n db
helm uninstall redis -n cache
helm uninstall vote -n frontend
helm uninstall result -n frontend
helm uninstall worker -n backend
```

## Chart Development

### Creating a New Chart

```bash
# Create a new chart
helm create my-chart

# Lint a chart
helm lint ./my-chart

# Dry-run to see rendered templates
helm install my-release ./my-chart --dry-run --debug -n my-namespace
```

### Template Testing

```bash
# Test template rendering
helm template my-release ./my-chart -n my-namespace

# Test with custom values
helm template my-release ./my-chart -f custom-values.yaml -n my-namespace
```

### Package Charts

```bash
# Package a chart
helm package ./db-chart

# This creates db-0.1.0.tgz
```

## Network Policies

All Helm charts include NetworkPolicy templates for network isolation and security. Network policies are **enabled by default** in all charts.

### Database Chart Network Policy

The database chart includes a NetworkPolicy that:
- Isolates PostgreSQL to only accept connections from authorized namespaces
- Allows connections from `backend` namespace (worker service)
- Allows connections from `frontend` namespace (result service)
- Denies all other ingress traffic

### Enabling/Disabling Network Policies

```bash
# Disable network policy for a chart
helm upgrade db ./helm/db-chart \
  --set networkPolicy.enabled=false \
  -n db

# Enable network policy (default)
helm upgrade db ./helm/db-chart \
  --set networkPolicy.enabled=true \
  -n db
```

### Network Policy Configuration

Each chart's `values.yaml` includes network policy configuration:

```yaml
networkPolicy:
  enabled: true
  allowFromBackend: true
  allowFromFrontend: true
  allowFromNamespaces: []  # Additional namespaces if needed
```

## Pod Security Standards (PSA)

When creating namespaces for Helm deployments, ensure they include PSA labels:

```bash
# Create namespace with PSA labels
kubectl create namespace db --dry-run=client -o yaml | \
  kubectl label --local -f - \
    pod-security.kubernetes.io/enforce=restricted \
    pod-security.kubernetes.io/audit=restricted \
    pod-security.kubernetes.io/warn=restricted \
    name=db -o yaml | kubectl apply -f -
```

Or create namespaces manually with PSA labels before deploying Helm charts.

## Best Practices

1. **Version Management**: Always increment chart versions in `Chart.yaml` when making changes
2. **Values Validation**: Use schema validation in `values.schema.json` for type checking
3. **Security**: Never commit secrets in `values.yaml`; use external secret management
4. **Resource Limits**: Always set appropriate resource requests and limits
5. **Namespaces**: Use namespaces to isolate environments (dev, staging, prod)
6. **Dependencies**: Use `Chart.yaml` dependencies for complex applications
7. **Testing**: Test charts in a non-production environment first
8. **Network Policies**: Keep network policies enabled for production deployments
9. **PSA**: Ensure namespaces have PSA labels before deploying charts

## Troubleshooting

### Check Chart Status

```bash
# View release status
helm status <release-name> -n <namespace>

# View release values
helm get values <release-name> -n <namespace>
```

### Debug Template Rendering

```bash
# Dry-run with debug output
helm install <release-name> ./<chart> --dry-run --debug -n <namespace>

# Template without installing
helm template <release-name> ./<chart> -n <namespace>
```

### Common Issues

**Issue: Chart installation fails**
```bash
# Check for syntax errors
helm lint ./<chart>

# Verify Kubernetes resources
kubectl get all -n <namespace>
```

**Issue: Values not applying**
```bash
# Verify values are being read
helm get values <release-name> -n <namespace>

# Check template rendering
helm template <release-name> ./<chart> -f <values-file> -n <namespace>
```

**Issue: Pods not starting**
```bash
# Check pod status
kubectl get pods -n <namespace>

# View pod logs
kubectl logs <pod-name> -n <namespace>

# Describe pod for events
kubectl describe pod <pod-name> -n <namespace>
```

## Chart Versions

| Chart | Version | App Version |
|-------|---------|-------------|
| db-chart | 0.1.0 | 0.1.0 |
| redis-chart | 0.1.0 | 0.1.0 |
| vote-chart | 0.1.0 | 0.1.0 |
| result-chart | 0.1.0 | 0.1.0 |
| worker-chart | 0.1.0 | 0.1.0 |

## Notes

- All charts use Helm 3 format (apiVersion: v2)
- Charts are designed to be deployed independently but have service dependencies
- Service names follow the pattern: `<chart-name>-<service-type>` (e.g., `db-postgres`)
- Database secrets are created by the db-chart and referenced by other charts
- Ingress resources require NGINX Ingress Controller to be installed
- Storage classes must be configured in your cluster for PVCs to bind

## Additional Resources

- [Helm Documentation](https://helm.sh/docs/)
- [Helm Best Practices](https://helm.sh/docs/chart_best_practices/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

