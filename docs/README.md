# Production OpenShift Platform Engineering Lab

**Cluster:** lab.ocp.lan
**Version:** OpenShift 4.19.11
**Purpose:** Production-grade platform engineering learning environment

## 🎯 Learning Objectives

Build and operate a production-ready Kubernetes platform with:
- GitOps-based infrastructure management
- Enterprise-grade security and secrets management
- Service mesh and advanced networking
- Comprehensive observability stack
- Policy-driven governance
- Production platform services (Kafka, etc.)

## 📚 Documentation Structure

### Phase 0: Foundation
- [00-foundation/](00-foundation/) - Cluster setup, DNS configuration, networking

### Phase 1: GitOps Bootstrap
- [01-gitops/](01-gitops/) - ArgoCD installation, App of Apps pattern

### Phase 2: Security & Secrets
- [02-security/](02-security/) - Vault, External Secrets Operator, cert-manager

### Phase 3: Networking
- [03-networking/](03-networking/) - Envoy Gateway, External DNS, Linkerd

### Phase 4: Governance
- [04-governance/](04-governance/) - Kyverno policies, Pod Security Standards

### Phase 5: Observability
- [05-observability/](05-observability/) - OTEL, Prometheus, Grafana, Loki, Jaeger

### Phase 6: Platform Services
- [06-platform-services/](06-platform-services/) - Kafka, Schema Registry, Kafka Connect

### Phase 7: Applications
- [07-applications/](07-applications/) - Microservices, CI/CD

### Session Logs
- [sessions/](sessions/) - Daily session notes and progress tracking

## 🔐 Access Information

**Console:** https://console-openshift-console.apps.lab.ocp.lan:8443
**API:** https://api.lab.ocp.lan:6443
**Username:** kubeadmin
**Password:** *(stored in ~/ocp-install/auth/kubeadmin-password)*

## 📋 Current Status

| Component | Status | Notes |
|-----------|--------|-------|
| Cluster | ✅ Running | 3 control plane, 3 worker nodes |
| DNS | ✅ Fixed | Wildcard apps route corrected |
| Console | ✅ Accessible | Via HAProxy on port 8443 |
| ArgoCD | ⏳ Pending | Next step |

## 🚀 Quick Start

```bash
# Login to cluster
oc login -u kubeadmin -p EPpXj-6GQZj-Nd2vX-NpnGQ https://api.lab.ocp.lan:6443

# Verify cluster health
oc get nodes
oc get co

# SSH to bootstrap (if needed)
ssh -i ~/.ssh/id_ed25519_core core@192.168.22.200

📖 Session Logs

- sessions/2025-10-07-session-001.md - Cluster health check, DNS fix
- Session 002 - Next: ArgoCD bootstrap

---Last Updated: 2025-10-07Maintainer: Platform Engineering Team
