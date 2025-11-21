# Kubernetes Manifests

This directory contains Kubernetes manifests for deploying a distributed voting application (Dogs vs Cats) on a Kubernetes cluster. The application consists of multiple microservices organized into different namespaces for better isolation and management.

## Architecture Overview

The application follows a microservices architecture with the following components:

```
┌─────────────┐      ┌─────────────┐
│    Vote     │─────▶│    Redis    │
│  (Frontend) │      │   (Cache)   │
└─────────────┘      └─────────────┘
                            │
                            ▼
                     ┌─────────────┐
                     │   Worker    │
                     │  (Backend)  │
                     └─────────────┘
                            │
                            ▼
┌─────────────┐      ┌─────────────┐
│   Result    │─────▶│ PostgreSQL  │
│  (Frontend) │      │  (Database) │
└─────────────┘      └─────────────┘
```

## Directory Structure

```
K8s/
├── db/          # PostgreSQL database components
├── redis/       # Redis cache components
├── vote/        # Voting frontend application
├── result/      # Results display frontend application
└── worker/      # Background worker service
```

## Components

### 1. Database (`db/`)

PostgreSQL 15 database for persistent storage of voting results.

**Files:**
- `Statefulset.yaml` - PostgreSQL StatefulSet with persistent storage
- `Service.yaml` - ClusterIP service exposing PostgreSQL on port 5432
- `Secret.yaml` - Database credentials (POSTGRES_DB, POSTGRES_USER, POSTGRES_PASSWORD)
- `Configmap.yaml` - PostgreSQL configuration (shared_buffers, work_mem, etc.)
- `PVC.yaml` - PersistentVolumeClaim for 10Gi storage
- `Namespace.yaml` - Creates the `db` namespace

**Key Features:**
- StatefulSet for stable network identity and persistent storage
- Health checks (liveness and readiness probes)
- Resource limits: 256Mi-512Mi memory, 250m-1000m CPU
- Persistent storage: 10Gi ReadWriteOnce

**Namespace:** `db`

### 2. Redis Cache (`redis/`)

Redis 7 cache for temporary vote storage and message queuing.

**Files:**
- `Statefulset.yaml` - Redis StatefulSet with persistent storage
- `Service.yaml` - ClusterIP service exposing Redis on port 6379
- `Configmap.yaml` - Redis configuration (maxmemory: 256mb, eviction policy: allkeys-lru)
- `PVC.yaml` - PersistentVolumeClaim for 8Gi storage
- `Namespace.yaml` - Creates the `cache` namespace

**Key Features:**
- StatefulSet for stable network identity
- Health checks using `redis-cli ping`
- Resource limits: 128Mi-256Mi memory, 100m-500m CPU
- Persistent storage: 8Gi ReadWriteOnce
- Memory eviction policy configured

**Namespace:** `cache`

### 3. Vote Service (`vote/`)

Frontend application for casting votes (Dogs vs Cats).

**Files:**
- `Deployment.yaml` - Deployment with 2 replicas
- `Service.yaml` - NodePort service on port 8080
- `Ingress.yaml` - Ingress resource for external access (vote.dogsvscats.tactful)

**Key Features:**
- 2 replicas for high availability
- Connects to Redis for vote storage
- Health checks on `/health` endpoint
- Security context: runs as non-root user (UID 1000)
- Resource limits: 100Mi-128Mi memory, 100m-500m CPU
- Image: `nadermamdouh869/vote:v1`

**Namespace:** `frontend`

**Environment Variables:**
- `REDIS_HOST`: redis.cache.svc.cluster.local
- `REDIS_PORT`: 6379
- `REDIS_PASSWORD`: "" (empty)

### 4. Result Service (`result/`)

Frontend application for displaying voting results.

**Files:**
- `Deployment.yaml` - Deployment with 2 replicas
- `Service.yaml` - NodePort service on port 8081
- `Ingress.yaml` - Ingress resource for external access (result.dogsvscats.tactful)
- `Namespace.yaml` - Creates the `frontend` namespace

**Key Features:**
- 2 replicas for high availability
- Connects to PostgreSQL for reading results
- Health checks on `/health` endpoint
- Security context: runs as non-root user (UID 1000)
- Resource limits: 100Mi-128Mi memory, 100m-500m CPU
- Image: `nadermamdouh869/result:v3`
- Uses secrets for database credentials

**Namespace:** `frontend`

**Environment Variables:**
- `DB_HOST`: postgres.db.svc.cluster.local
- `DB_PORT`: 5432
- `DB_NAME`: postgres
- `DB_USER`: From secret `postgres-secret`
- `DB_PASSWORD`: From secret `postgres-secret`

### 5. Worker Service (`worker/`)

Background worker service that processes votes from Redis and stores them in PostgreSQL.

**Files:**
- `Deployment.yaml` - Deployment with 2 replicas
- `Namespace.yaml` - Creates the `backend` namespace

**Key Features:**
- 2 replicas for high availability
- Connects to both Redis (reads votes) and PostgreSQL (writes results)
- Security context: runs as non-root user (UID 1000)
- Resource limits: 100Mi-128Mi memory, 100m-500m CPU
- Image: `nadermamdouh869/worker:v1`
- Uses secrets for database credentials

**Namespace:** `backend`

**Environment Variables:**
- `REDIS_HOST`: redis.cache.svc.cluster.local
- `REDIS_PORT`: 6379
- `REDIS_PASSWORD`: "" (empty)
- `DB_HOST`: postgres.db.svc.cluster.local
- `DB_PORT`: 5432
- `DB_NAME`: postgres
- `DB_USER`: From secret `postgres-secret`
- `DB_PASSWORD`: From secret `postgres-secret`

## Namespaces

The application uses four namespaces for logical separation:

1. **`db`** - Database components (PostgreSQL)
2. **`cache`** - Caching layer (Redis)
3. **`frontend`** - User-facing services (vote, result)
4. **`backend`** - Background processing (worker)

## Deployment Order

For a successful deployment, apply the manifests in the following order:

1. **Namespaces** (all namespace YAMLs - includes PSA labels)
2. **Secrets and ConfigMaps** (db/Secret.yaml, db/Configmap.yaml, redis/Configmap.yaml)
3. **Persistent Storage** (db/PVC.yaml, redis/PVC.yaml)
4. **StatefulSets** (db/Statefulset.yaml, redis/Statefulset.yaml)
5. **Services** (db/Service.yaml, redis/Service.yaml, vote/Service.yaml, result/Service.yaml)
6. **Deployments** (vote/Deployment.yaml, result/Deployment.yaml, worker/Deployment.yaml)
7. **Network Policies** (db/NetworkPolicy.yaml, redis/NetworkPolicy.yaml, frontend/NetworkPolicy.yaml, backend/NetworkPolicy.yaml, cache/NetworkPolicy.yaml)
8. **Ingress** (vote/Ingress.yaml, result/Ingress.yaml)

## Quick Start

### Prerequisites

- Kubernetes cluster (v1.20+)
- kubectl configured to access your cluster
- NGINX Ingress Controller installed (for Ingress resources)
- Storage class configured for PersistentVolumeClaims

### Deploy All Components

```bash
# Apply namespaces first
kubectl apply -f db/Namespace.yaml
kubectl apply -f redis/Namespace.yaml
kubectl apply -f result/Namespace.yaml
kubectl apply -f worker/Namespace.yaml

# Apply secrets and configmaps
kubectl apply -f db/Secret.yaml
kubectl apply -f db/Configmap.yaml
kubectl apply -f redis/Configmap.yaml

# Apply persistent volume claims
kubectl apply -f db/PVC.yaml
kubectl apply -f redis/PVC.yaml

# Apply statefulsets
kubectl apply -f db/Statefulset.yaml
kubectl apply -f redis/Statefulset.yaml

# Apply services
kubectl apply -f db/Service.yaml
kubectl apply -f redis/Service.yaml
kubectl apply -f vote/Service.yaml
kubectl apply -f result/Service.yaml

# Apply deployments
kubectl apply -f vote/Deployment.yaml
kubectl apply -f result/Deployment.yaml
kubectl apply -f worker/Deployment.yaml

# Apply ingress
kubectl apply -f vote/Ingress.yaml
kubectl apply -f result/Ingress.yaml
```

### Verify Deployment

```bash
# Check all pods are running
kubectl get pods --all-namespaces

# Check services
kubectl get svc --all-namespaces

# Check ingress
kubectl get ingress --all-namespaces

# View logs
kubectl logs -n frontend -l app=vote
kubectl logs -n frontend -l app=result
kubectl logs -n backend -l app=worker
```

## Accessing the Application

After deployment, the application can be accessed via:

- **Vote Interface**: `http://vote.dogsvscats.tactful` (or via NodePort)
- **Results Interface**: `http://result.dogsvscats.tactful` (or via NodePort)

**Note:** Ensure your `/etc/hosts` file includes entries for these domains pointing to your ingress controller's IP, or configure DNS accordingly.

## Data Flow

1. **User votes** → Vote service receives vote → Stores in Redis
2. **Worker** → Reads votes from Redis → Processes and stores in PostgreSQL
3. **User views results** → Result service queries PostgreSQL → Displays results

## Security Considerations

- **Non-root Containers**: All containers run as non-root users (UID 1000)
- **Privilege Escalation**: Disabled in all security contexts
- **Secrets Management**: Kubernetes secrets for sensitive data (database credentials)
- **Network Policies**: Implemented for database isolation and namespace segmentation
- **Pod Security Standards (PSA)**: All namespaces enforce restricted policy
- **Network Isolation**: Database and cache are isolated with NetworkPolicies
- Consider using sealed secrets or external secret management in production

### Network Policies

Network Policies are implemented to isolate the database and control traffic flow:
- **Database Isolation**: PostgreSQL only accepts connections from frontend and backend namespaces
- **Redis Isolation**: Redis only accepts connections from frontend and backend namespaces
- **Namespace Segmentation**: Each namespace has appropriate ingress/egress rules

See [NETWORK-POLICIES.md](./NETWORK-POLICIES.md) for detailed documentation.

### Pod Security Standards (PSA)

All namespaces are configured with the `restricted` PSA policy:
- Enforces non-root containers
- Prevents privilege escalation
- Requires security contexts

See [PSA-NAMESPACES.md](./PSA-NAMESPACES.md) for detailed documentation.

## Resource Requirements

### Minimum Cluster Resources

- **CPU**: ~2.5 cores (requests: ~1.1 cores)
- **Memory**: ~1.5 Gi (requests: ~700 Mi)
- **Storage**: 18 Gi (10 Gi for PostgreSQL + 8 Gi for Redis)

### Scaling

To scale the application:

```bash
# Scale vote service
kubectl scale deployment vote-deployment -n frontend --replicas=3

# Scale result service
kubectl scale deployment result-deployment -n frontend --replicas=3

# Scale worker service
kubectl scale deployment worker-deployment -n backend --replicas=3
```

**Note:** StatefulSets (PostgreSQL and Redis) are configured with 1 replica. Scaling these requires careful consideration of data consistency and replication.

## Troubleshooting

### Check Pod Status

```bash
kubectl get pods --all-namespaces
kubectl describe pod <pod-name> -n <namespace>
```

### View Logs

```bash
kubectl logs <pod-name> -n <namespace>
kubectl logs -f <pod-name> -n <namespace>  # Follow logs
```

### Check Services

```bash
kubectl get svc --all-namespaces
kubectl describe svc <service-name> -n <namespace>
```

### Database Connection Issues

```bash
# Test PostgreSQL connection
kubectl exec -it -n db <postgres-pod-name> -- psql -U postgres -d postgres

# Test Redis connection
kubectl exec -it -n cache <redis-pod-name> -- redis-cli ping
```

### Ingress Issues

```bash
# Check ingress controller
kubectl get pods -n ingress-nginx

# Check ingress resources
kubectl describe ingress -n frontend
```

## Maintenance

### Backup PostgreSQL

```bash
# Create a backup
kubectl exec -n db <postgres-pod-name> -- pg_dump -U postgres postgres > backup.sql
```

### Update Application Images

Edit the Deployment YAML files to change the image tag, then:

```bash
kubectl apply -f <deployment-file>
kubectl rollout restart deployment/<deployment-name> -n <namespace>
```

## Notes

- The secrets in `db/Secret.yaml` contain default credentials. **Change these in production!**
- The Ingress hostnames (`vote.dogsvscats.tactful`, `result.dogsvscats.tactful`) may need to be adjusted based on your DNS configuration
- Ensure your cluster has a default storage class configured for PVCs to be bound automatically
- Consider implementing network policies for enhanced security between namespaces

