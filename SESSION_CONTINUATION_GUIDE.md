# Session Continuation Guide for Claude

## Context
Production-grade OpenShift platform engineering lab for learning SRE/DevOps/DevSecOps.

**Student:** Damoke (damoke012@hotmail.com)
**Cluster:** lab.ocp.lan (OpenShift 4.19.11)

## Critical Instructions for Future Claude Sessions

1. **Read this file first** at the start of every session
2. **Check latest session log** in `docs/sessions/`
3. **Update TodoWrite** to track current progress
4. **Document everything** - Update docs as you work
5. **Teach, don't just do** - Explain production context
6. **Update this file** at end of session with current state

## Current Status (Last Updated: 2025-10-07)

### ✅ Completed
- Cluster health validated, DNS fixed
- Console access configured (HAProxy on port 8443)
- ArgoCD (OpenShift GitOps) installed
- GitHub repo created with SSH auth
- Documentation structure established

### 🔄 In Progress
- Setting up GitOps repository structure
- Pushing documentation to GitHub

### ⏳ Next Steps
1. Complete GitHub push
2. Configure ArgoCD to watch repo
3. Create App of Apps pattern
4. Deploy Vault + External Secrets Operator

## Access Credentials

### OpenShift
- Console: https://console-openshift-console.apps.lab.ocp.lan:8443
- API: https://api.lab.ocp.lan:6443
- User: kubeadmin / EPpXj-6GQZj-Nd2vX-NpnGQ
- Kubeconfig: ~/ocp-install/auth/kubeconfig

### ArgoCD
- URL: https://openshift-gitops-server-openshift-gitops.apps.lab.ocp.lan:8443
- User: admin / L5N7SkIOblxah1WwEDMGJR8d4yQAjcCr

### Git
- Repo: https://github.com/damoke012/platform-gitops
- SSH Key: ~/.ssh/github_key
- Local: ~/platform-gitops

## Platform Roadmap

1. **Secrets** - Vault, External Secrets Operator, cert-manager
2. **Networking** - Envoy Gateway, Linkerd, External DNS
3. **Governance** - Kyverno policies
4. **Observability** - OTEL, Prometheus, Grafana, Loki, Jaeger
5. **Platform** - Kafka (Strimzi), Schema Registry
6. **Apps** - Sample microservices, CI/CD

## Key Context

**Network:** External (192.168.1.x) ↔ HAProxy ↔ Internal (192.168.22.x)
**DNS:** *.apps.lab.ocp.lan → 192.168.22.201, 192.168.22.202
**Git:** Use /usr/bin/git (alias in ~/.bashrc)

## Session Workflow

START: Read this file, check session logs, review todos
DURING: Explain why, compare lab vs prod, update docs
END: Create session log, update this file, update todos, push to Git

---
Last Session: 2025-10-07 - DNS fix, ArgoCD install, GitHub setup
Next: Push docs to GitHub, configure ArgoCD repository connection
