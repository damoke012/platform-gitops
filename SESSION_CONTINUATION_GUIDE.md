# Session Continuation Guide for Claude Code

**Repository**: https://github.com/damoke012/platform-gitops
**User**: Damoke (damoke012@hotmail.com)
**Last Updated**: 2025-10-08 22:40 UTC

## Quick Status

Date:10/08/2025

**Current Phase**: Phase 1 - Internal OCI Registry Setup (Day 1 - Complete)
**Last Completed**: Harbor registry deployed and accessible
**Next Task**: Create Harbor projects and test image push/pull
**Completion**: ~20% of overall platform build

Date:10/07/2025
**Current Phase**: Phase 1 - Internal OCI Registry Setup (Day 1 - In Progress)
**Last Completed**: NFS storage infrastructure configured and verified
**Next Task**: Deploy Harbor registry using Helm
**Completion**: ~15% of overall platform build

## What We're Building

A **production-grade, airgapped OpenShift platform** for learning SRE/DevOps/DevSecOps skills. The user wants to
**create all Infrastructure as Code themselves** - your role is to guide, explain production concepts, and help
troubleshoot, NOT write code for them.

### Key Requirements
- ✅ Airgapped environment (no internet access to cluster)
- ✅ Internal OCI registry for all images (Harbor - CNCF choice)
- ✅ Security scanning at ALL stages (build, post-build, runtime)
- ✅ SBOM generation for every image
- ✅ Zero long-lived tokens/credentials
- ✅ Heavy use of Terraform and Ansible (mandatory)
- ✅ GitOps with ArgoCD
- ✅ ELK stack for observability (NOT Loki)

## Current Infrastructure

### Network Topology
External Network: 192.168.1.x (user's workstation)
                    ↓
            HAProxy (ocp-svc:8443)
                    ↓
Internal Network: 192.168.22.x
- ocp-svc:     192.168.22.1 (NFS server, DNS, HAProxy)
- Router-1:    192.168.22.201
- Router-2:    192.168.22.202
- Control-1:   192.168.22.11
- Control-2:   192.168.22.12
- Control-3:   192.168.22.13
- Worker-1:    192.168.22.101
- Worker-2:    192.168.22.102
- Worker-3:    192.168.22.103

### OpenShift Cluster
- **Version**: 4.19.11
- **Nodes**: 3 control plane + 3 workers
- **Console**: https://192.168.1.78:8443 (external access via HAProxy)
- **DNS**: 
