# Network Policies Documentation

This document explains the Network Policies implemented in this project for network isolation and security.

## Overview

Network Policies control traffic flow between pods and namespaces. They provide an additional layer of security by enforcing network segmentation.

## Network Policy Architecture

### Database Isolation (PostgreSQL)

**File**: `K8s/db/NetworkPolicy.yaml`

The PostgreSQL database is isolated and only allows connections from:
- **Backend namespace** (worker service) - Port 5432
- **Frontend namespace** (result service) - Port 5432

All other ingress traffic is denied by default.

### Redis Cache Isolation

**File**: `K8s/redis/NetworkPolicy.yaml`

Redis only allows connections from:
- **Frontend namespace** (vote service) - Port 6379
- **Backend namespace** (worker service) - Port 6379

### Frontend Namespace

**File**: `K8s/frontend/NetworkPolicy.yaml`

Frontend services (vote and result) can:
- **Receive ingress** from:
  - Ingress controller (for external access)
  - Same namespace (for service-to-service communication)
- **Send egress** to:
  - Cache namespace (Redis) - Port 6379
  - DB namespace (PostgreSQL) - Port 5432
  - DNS (kube-system) - Port 53
  - External HTTPS - Port 443

### Backend Namespace

**File**: `K8s/backend/NetworkPolicy.yaml`

Backend services (worker) can:
- **Receive ingress** from:
  - Same namespace (for service-to-service communication)
- **Send egress** to:
  - Cache namespace (Redis) - Port 6379
  - DB namespace (PostgreSQL) - Port 5432
  - DNS (kube-system) - Port 53

### Cache Namespace

**File**: `K8s/cache/NetworkPolicy.yaml`

Cache namespace has namespace-level policies for additional isolation.

## Network Policy Rules Summary

| Source Namespace | Target Namespace | Port | Purpose |
|----------------|------------------|------|---------|
| frontend | cache | 6379 | Vote service → Redis |
| backend | cache | 6379 | Worker service → Redis |
| frontend | db | 5432 | Result service → PostgreSQL |
| backend | db | 5432 | Worker service → PostgreSQL |
| ingress-nginx | frontend | 8080, 8081 | External access to vote/result |

## Deployment

### Using Kubernetes Manifests

```bash
# Apply all network policies
kubectl apply -f K8s/db/NetworkPolicy.yaml
kubectl apply -f K8s/redis/NetworkPolicy.yaml
kubectl apply -f K8s/frontend/NetworkPolicy.yaml
kubectl apply -f K8s/backend/NetworkPolicy.yaml
kubectl apply -f K8s/cache/NetworkPolicy.yaml
```

### Using Helm Charts

Network policies are enabled by default in Helm charts. To disable:

```bash
helm upgrade db ./helm/db-chart \
  --set networkPolicy.enabled=false \
  -n db
```

## Verification

### Check Network Policies

```bash
# List all network policies
kubectl get networkpolicies --all-namespaces

# View specific network policy
kubectl get networkpolicy postgres-network-policy -n db -o yaml

# Describe network policy
kubectl describe networkpolicy postgres-network-policy -n db
```

### Test Network Isolation

```bash
# Try to connect to PostgreSQL from unauthorized namespace (should fail)
kubectl run test-pod --image=postgres:15-alpine --rm -it --restart=Never -n default -- \
  psql -h postgres.db.svc.cluster.local -U postgres

# Should fail with connection timeout or refused
```

## Important Notes

1. **Namespace Labels**: Network policies rely on namespace labels. Ensure namespaces have the `name` label:
   ```yaml
   labels:
     name: db
   ```

2. **Default Deny**: Network policies use a default-deny model. Only explicitly allowed traffic is permitted.

3. **DNS**: DNS resolution (port 53) is typically allowed to ensure service discovery works.

4. **Ingress Controller**: The ingress controller namespace must be labeled correctly for frontend access to work.

## Troubleshooting

### Pods Cannot Connect

1. Check if network policies are applied:
   ```bash
   kubectl get networkpolicies -n <namespace>
   ```

2. Verify namespace labels:
   ```bash
   kubectl get namespace <namespace> -o yaml | grep labels
   ```

3. Check pod connectivity:
   ```bash
   kubectl exec -it <pod-name> -n <namespace> -- ping <target-service>
   ```

### Ingress Not Working

Ensure the ingress controller namespace has the correct label:
```bash
kubectl label namespace ingress-nginx name=ingress-nginx
```

## Security Benefits

1. **Database Isolation**: PostgreSQL is only accessible from authorized namespaces
2. **Principle of Least Privilege**: Each namespace only has access to what it needs
3. **Defense in Depth**: Additional security layer beyond namespace isolation
4. **Compliance**: Meets security requirements for network segmentation

## Additional Resources

- [Kubernetes Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [Network Policy Examples](https://kubernetes.io/docs/tasks/administer-cluster/declare-network-policy/)

