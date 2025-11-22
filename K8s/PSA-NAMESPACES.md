# Pod Security Standards (PSA) Configuration

This document explains how Pod Security Standards (PSA) are configured in this project.

## Overview

Pod Security Standards (PSA) enforce security policies at the namespace level. All namespaces in this project are configured with the **restricted** policy level, which is the most secure option.

## PSA Labels

All namespaces include the following labels:

```yaml
labels:
  pod-security.kubernetes.io/enforce: restricted
  pod-security.kubernetes.io/audit: restricted
  pod-security.kubernetes.io/warn: restricted
```

### Policy Levels

- **enforce**: Pods that violate the policy are rejected
- **audit**: Violations are logged but not rejected
- **warn**: Users are warned about violations

### Restricted Policy Requirements

The `restricted` policy enforces:
- Must not run as root (UID 0)
- Must not allow privilege escalation
- Must run as a non-root user
- Must drop all capabilities
- Must not use host namespaces
- Must not use hostPath volumes
- Must use read-only root filesystem (where possible)

## Namespaces with PSA

The following namespaces are configured with PSA:

1. **db** - Database namespace
2. **cache** - Redis cache namespace
3. **frontend** - Frontend services namespace
4. **backend** - Backend worker namespace

## Verification

To verify PSA is working:

```bash
# Check namespace labels
kubectl get namespace db -o yaml | grep pod-security

# Try to create a pod that violates PSA (should be rejected)
kubectl run test-pod --image=nginx --restart=Never -n db
# Should fail with: "violates PodSecurity"
```

## Compatibility

All pods in this project are designed to be compatible with the restricted policy:
- All containers run as non-root users (UID 1000)
- Privilege escalation is disabled
- Security contexts are properly configured

## Additional Resources

- [Kubernetes Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
- [Pod Security Admission](https://kubernetes.io/docs/concepts/security/pod-security-admission/)


