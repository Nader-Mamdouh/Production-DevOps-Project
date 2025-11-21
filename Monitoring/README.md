# Monitoring Stack

This directory contains configuration files for deploying a comprehensive monitoring stack on Kubernetes using Prometheus, Grafana, and Alertmanager. The stack is deployed using the `kube-prometheus-stack` Helm chart, which provides a complete monitoring solution with pre-configured dashboards, alerting rules, and service discovery.

## Overview

The monitoring stack consists of:

- **Prometheus**: Time-series database for metrics collection and storage
- **Grafana**: Visualization and dashboarding platform
- **Alertmanager**: Alert routing and notification management
- **Service Monitors**: Automatic discovery and monitoring of Kubernetes services
- **Prometheus Operator**: Manages Prometheus and Alertmanager instances

## Architecture

```
┌─────────────────┐
│   Prometheus    │◄─── Collects metrics from Kubernetes and applications
└────────┬────────┘
         │
         ├───► ┌─────────────────┐
         │     │  Alertmanager   │◄─── Manages alerts and notifications
         │     └─────────────────┘
         │
         └───► ┌─────────────────┐
               │    Grafana      │◄─── Visualizes metrics and dashboards
               └─────────────────┘
```

## Directory Structure

```
Monitoring/
├── alert-manager.yaml           # Custom Alertmanager configuration values
├── Ingress-promethus.yaml      # Ingress for Prometheus UI
├── Ingress-grafana.yaml         # Ingress for Grafana UI
├── Ingress-alertManager.yaml    # Ingress for Alertmanager UI
└── README.md                    # This file
```

## Files Description

### `alert-manager.yaml`

Custom values file for Alertmanager configuration. This file configures:

- **Replicas**: Sets Alertmanager to 2 replicas for high availability
- **AlertmanagerConfig Selector**: Configures label matching for alert configurations
- **Matcher Strategy**: Sets the matching strategy to `None` for flexible alert routing

**Key Features:**
- High availability with 2 replicas
- Proper label selectors to avoid configuration errors
- Flexible alert matching strategy

### Ingress Files

Three Ingress resources provide external access to the monitoring services:

1. **`Ingress-promethus.yaml`**: Exposes Prometheus UI
   - Host: `prometheus.dogsvscats.tactful`
   - Service: `prometheus-operated` (port 9090)

2. **`Ingress-grafana.yaml`**: Exposes Grafana UI
   - Host: `grafana.dogsvscats.tactful`
   - Service: `monitoring-grafana` (port 80)

3. **`Ingress-alertManager.yaml`**: Exposes Alertmanager UI
   - Host: `alertmanager.dogsvscats.tactful`
   - Service: `alertmanager-operated` (port 9093)

## Prerequisites

Before deploying the monitoring stack, ensure you have:

1. **Kubernetes Cluster**: A running Kubernetes cluster (v1.20+)
2. **kubectl**: Configured to access your cluster
3. **Helm 3.x**: Installed and configured
4. **NGINX Ingress Controller**: Installed and running (required for Ingress resources)
5. **DNS Configuration**: Access to configure DNS or `/etc/hosts` entries for the ingress hosts

### Verify Prerequisites

```bash
# Check Kubernetes access
kubectl cluster-info

# Check Helm version
helm version

# Verify NGINX Ingress Controller
kubectl get pods -n ingress-nginx

# Check if monitoring namespace exists
kubectl get namespace monitoring
```

## Installation

### Step 1: Add Prometheus Community Helm Repository

```bash
# Add the Prometheus Community Helm repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

# Update Helm repositories
helm repo update

# Verify repository was added
helm repo list
```

### Step 2: Create Monitoring Namespace

```bash
# Create the monitoring namespace
kubectl create namespace monitoring

# Verify namespace creation
kubectl get namespace monitoring
```

### Step 3: Install kube-prometheus-stack

```bash
# Navigate to the Monitoring directory
cd Monitoring

# Install the monitoring stack with alert-manager.yaml
helm install monitoring prometheus-community/kube-prometheus-stack \
  -n monitoring \
  -f ./alert-manager.yaml
```

**Installation Options:**

```bash
# Install with default values only (no custom configuration)
helm install monitoring prometheus-community/kube-prometheus-stack -n monitoring

# Install with alert-manager.yaml (recommended)
helm install monitoring prometheus-community/kube-prometheus-stack \
  -n monitoring \
  -f ./alert-manager.yaml
```

### Step 4: Apply Ingress Resources

After the Helm chart is installed, apply the Ingress resources:

```bash
# Apply all Ingress resources
kubectl apply -f Ingress-promethus.yaml
kubectl apply -f Ingress-grafana.yaml
kubectl apply -f Ingress-alertManager.yaml

# Or apply all at once
kubectl apply -f Ingress-*.yaml

# Verify Ingress resources
kubectl get ingress -n monitoring
```

### Step 5: Verify Installation

```bash
# Check all pods are running
kubectl get pods -n monitoring

# Check services
kubectl get svc -n monitoring

# Check ingress
kubectl get ingress -n monitoring

# View Helm release status
helm status monitoring -n monitoring
```

**Expected Output:**

You should see pods for:
- `prometheus-monitoring-kube-prometheus-prometheus-*`
- `alertmanager-monitoring-kube-prometheus-alertmanager-*`
- `monitoring-grafana-*`
- `monitoring-kube-prometheus-operator-*`
- `monitoring-kube-state-metrics-*`
- `monitoring-prometheus-node-exporter-*`

## Accessing the Services

### DNS Configuration

Add the following entries to your `/etc/hosts` file (or configure DNS):

```
<INGRESS_IP>  prometheus.dogsvscats.tactful
<INGRESS_IP>  grafana.dogsvscats.tactful
<INGRESS_IP>  alertmanager.dogsvscats.tactful
```

**Get Ingress IP:**

```bash
# Get the external IP of the ingress controller
kubectl get svc -n ingress-nginx

# Or get the ingress IP directly
kubectl get ingress -n monitoring -o wide
```

### Access URLs

Once DNS is configured, access the services at:

- **Prometheus**: http://prometheus.dogsvscats.tactful
- **Grafana**: http://grafana.dogsvscats.tactful
  - Default username: `admin`
  - Default password: Check your values file or run:
    ```bash
    kubectl get secret --namespace monitoring monitoring-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
    ```
- **Alertmanager**: http://alertmanager.dogsvscats.tactful

### Port Forwarding (Alternative Access)

If Ingress is not available, use port forwarding:

```bash
# Prometheus
kubectl port-forward -n monitoring svc/prometheus-operated 9090:9090
# Access at http://localhost:9090

# Grafana
kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80
# Access at http://localhost:3000

# Alertmanager
kubectl port-forward -n monitoring svc/alertmanager-operated 9093:9093
# Access at http://localhost:9093
```

## Configuration

### Alertmanager Configuration

The `alert-manager.yaml` file configures:

1. **High Availability**: 2 replicas for fault tolerance
2. **Label Selectors**: Ensures AlertmanagerConfig resources are properly matched
3. **Matcher Strategy**: Flexible alert routing without namespace restrictions

**Key Settings:**

```yaml
alertmanager:
  alertmanagerSpec:
    replicas: 2  # High availability
    alertmanagerConfigSelector:
      matchLabels:
        release: monitoring
    alertmanagerConfigMatcherStrategy:
      type: None  # Flexible matching
```

### Customizing Prometheus

To customize Prometheus settings, you can add them to `alert-manager.yaml` or create additional values files:

```yaml
prometheus:
  prometheusSpec:
    # Retention period
    retention: 30d
    retentionSize: 50GB
    
    # Replicas for HA
    replicas: 2
    
    # Resource limits
    resources:
      requests:
        memory: 2Gi
        cpu: 1000m
      limits:
        memory: 4Gi
        cpu: 2000m
    
    # Storage
    storageSpec:
      volumeClaimTemplate:
        spec:
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 50Gi
```

### Customizing Grafana

To customize Grafana settings, add them to `alert-manager.yaml` or create additional values files:

```yaml
grafana:
  # Admin credentials
  adminUser: admin
  adminPassword: your-secure-password
  
  # Persistence
  persistence:
    enabled: true
    size: 10Gi
    storageClassName: standard
  
  # Resources
  resources:
    requests:
      memory: 256Mi
      cpu: 100m
    limits:
      memory: 512Mi
      cpu: 500m
  
  # Ingress (alternative to separate Ingress file)
  ingress:
    enabled: true
    ingressClassName: nginx
    hosts:
      - grafana.dogsvscats.tactful
```

## Monitoring Your Application

### ServiceMonitor

To monitor your application services, create ServiceMonitor resources. The Prometheus Operator will automatically discover and scrape metrics from services with matching ServiceMonitors.

**Example ServiceMonitor for vote service:**

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: vote-service-monitor
  namespace: frontend
  labels:
    release: monitoring
spec:
  selector:
    matchLabels:
      app: vote
  endpoints:
  - port: 8080
    path: /metrics
    interval: 30s
```

### PodMonitor

For pod-level monitoring:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PodMonitor
metadata:
  name: vote-pod-monitor
  namespace: frontend
  labels:
    release: monitoring
spec:
  selector:
    matchLabels:
      app: vote
  podMetricsEndpoints:
  - port: metrics
    interval: 30s
```

### PrometheusRule

Create custom alerting rules:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: application-alerts
  namespace: monitoring
  labels:
    release: monitoring
spec:
  groups:
  - name: application.rules
    interval: 30s
    rules:
    - alert: HighErrorRate
      expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.05
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "High error rate detected"
        description: "Error rate is above 5% for 5 minutes"
```

## Management

### Upgrade the Stack

```bash
# Update Helm repository
helm repo update

# Upgrade to latest version
helm upgrade monitoring prometheus-community/kube-prometheus-stack \
  -n monitoring \
  -f ./alert-manager.yaml

# Upgrade to specific version
helm upgrade monitoring prometheus-community/kube-prometheus-stack \
  --version <chart-version> \
  -n monitoring \
  -f ./alert-manager.yaml
```

### View Release Information

```bash
# View release status
helm status monitoring -n monitoring

# View release values
helm get values monitoring -n monitoring

# View all release information
helm get all monitoring -n monitoring
```

### Rollback

```bash
# View release history
helm history monitoring -n monitoring

# Rollback to previous version
helm rollback monitoring -n monitoring

# Rollback to specific revision
helm rollback monitoring 2 -n monitoring
```

### Uninstall

**⚠️ WARNING**: This will delete all monitoring data and configurations!

```bash
# Uninstall the monitoring stack
helm uninstall monitoring -n monitoring

# Delete the namespace (optional)
kubectl delete namespace monitoring
```

## Troubleshooting

### Pods Not Starting

```bash
# Check pod status
kubectl get pods -n monitoring

# Describe pod for events
kubectl describe pod <pod-name> -n monitoring

# View pod logs
kubectl logs <pod-name> -n monitoring

# View previous container logs (if crashed)
kubectl logs <pod-name> -n monitoring --previous
```

### Prometheus Not Scraping Targets

```bash
# Check ServiceMonitor resources
kubectl get servicemonitor --all-namespaces

# Check Prometheus targets in UI
# Navigate to Prometheus UI -> Status -> Targets

# Check Prometheus logs
kubectl logs -n monitoring -l app.kubernetes.io/name=prometheus
```

### Grafana Login Issues

```bash
# Get Grafana admin password
kubectl get secret --namespace monitoring monitoring-grafana \
  -o jsonpath="{.data.admin-password}" | base64 --decode ; echo

# Reset Grafana admin password
kubectl patch secret -n monitoring monitoring-grafana \
  -p '{"data":{"admin-password":"'$(echo -n 'newpassword' | base64)'"}}'
```

### Ingress Not Working

```bash
# Check Ingress controller
kubectl get pods -n ingress-nginx

# Check Ingress resources
kubectl get ingress -n monitoring
kubectl describe ingress -n monitoring

# Check Ingress controller logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller
```

### Alertmanager Not Receiving Alerts

```bash
# Check Alertmanager status
kubectl get pods -n monitoring -l app.kubernetes.io/name=alertmanager

# Check Alertmanager logs
kubectl logs -n monitoring -l app.kubernetes.io/name=alertmanager

# Verify AlertmanagerConfig
kubectl get alertmanagerconfig -n monitoring

# Check Prometheus alerting configuration
# Navigate to Prometheus UI -> Status -> Configuration
```

### High Resource Usage

```bash
# Check resource usage
kubectl top pods -n monitoring

# Adjust resource limits in alert-manager.yaml file
# Then upgrade the release
helm upgrade monitoring prometheus-community/kube-prometheus-stack \
  -n monitoring \
  -f ./alert-manager.yaml
```

## Best Practices

1. **Security**:
   - Change default Grafana admin password
   - Use RBAC for Prometheus and Grafana access
   - Enable TLS for Ingress resources
   - Use secrets for sensitive configuration

2. **Performance**:
   - Set appropriate retention periods
   - Configure resource limits
   - Use persistent storage for Grafana
   - Enable high availability (multiple replicas)

3. **Monitoring**:
   - Create ServiceMonitors for all applications
   - Define meaningful alerting rules
   - Organize dashboards in Grafana
   - Regular backup of Grafana dashboards

4. **Maintenance**:
   - Regularly update Helm charts
   - Monitor disk usage for Prometheus
   - Review and tune alerting rules
   - Document custom dashboards and alerts

## Useful Commands

```bash
# Get Prometheus URL
kubectl get svc -n monitoring prometheus-operated

# Get Grafana admin password
kubectl get secret -n monitoring monitoring-grafana \
  -o jsonpath="{.data.admin-password}" | base64 --decode ; echo

# Port forward to Prometheus
kubectl port-forward -n monitoring svc/prometheus-operated 9090:9090

# Port forward to Grafana
kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80

# View Prometheus targets
kubectl port-forward -n monitoring svc/prometheus-operated 9090:9090
# Then visit http://localhost:9090/targets

# Check Alertmanager configuration
kubectl get alertmanagerconfig -n monitoring -o yaml

# View all ServiceMonitors
kubectl get servicemonitor --all-namespaces

# View all PrometheusRules
kubectl get prometheusrule --all-namespaces
```

## Additional Resources

- [kube-prometheus-stack Chart Documentation](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Alertmanager Documentation](https://prometheus.io/docs/alerting/latest/alertmanager/)
- [Prometheus Operator Documentation](https://github.com/prometheus-operator/prometheus-operator)

## Notes

- The Ingress hostnames (`*.dogsvscats.tactful`) should be configured in your DNS or `/etc/hosts` file
- Default Grafana credentials should be changed in production
- Prometheus retention and storage should be configured based on your needs
- ServiceMonitors require the `release: monitoring` label to be discovered
- All Ingress resources use the `nginx` ingress class - ensure NGINX Ingress Controller is installed

