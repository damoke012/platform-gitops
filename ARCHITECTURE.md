# Production Airgapped Platform Architecture

## Overview
Enterprise-grade, airgapped Kubernetes platform with complete CI/CD, security scanning, observability, and
compliance.

## Key Requirements
- ✅ Airgapped environment (no internet access)
- ✅ Internal OCI registry for all images
- ✅ Zero long-lived tokens/credentials
- ✅ Security scanning at all stages (build, post-build, runtime)
- ✅ SBOM generation for compliance
- ✅ Infrastructure as Code (Terraform + Ansible)
- ✅ GitOps-based deployments (ArgoCD)
- ✅ Policy enforcement (Kyverno)
- ✅ Comprehensive observability with ELK stack

## Architecture Diagram

┌─────────────────────────────────────────────────────────────────┐
│                     External (Simulated)                        │
│  GitHub → Image Mirror → Validation → Internal Registry         │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│                    Internal OCI Registry                        │
│              (Quay or Harbor - HA, Scanning)                    │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│                      CI/CD Pipeline (Tekton)                    │
│                                                                 │
│  Source → Build → Scan → Test → SBOM → Sign → Deploy          │
│    ↓       ↓      ↓       ↓       ↓      ↓       ↓            │
│   Git   Container Security Unit  Syft  Cosign  ArgoCD         │
│         Build    Trivy   Tests                                 │
│                SonarQube                                        │
│                 Aqua                                           │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│                  Runtime Security Scanning                      │
│                                                                 │
│  Aqua Enforcer (DaemonSet) → Runtime Protection                │
│  - Image scanning at runtime                                   │
│  - Drift detection                                             │
│  - Behavioral monitoring                                       │
│  - CVE runtime blocking                                        │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│                    Secrets Management                           │
│                                                                 │
│  Vault (HA) → External Secrets Operator → Workloads           │
│  - Auto-rotation                                               │
│  - Transit encryption                                          │
│  - Audit logging                                               │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│                    Application Platform                         │
│                                                                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐          │
│  │   Linkerd   │  │    Envoy    │  │   Kyverno   │          │
│  │Service Mesh │  │   Gateway   │  │  Policies   │          │
│  └─────────────┘  └─────────────┘  └─────────────┘          │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│                    Observability Stack (ELK)                    │
│                                                                 │
│  Metrics:  Prometheus → Grafana                                │
│            Node Exporter (all nodes)                           │
│                                                                 │
│  Logs:     Filebeat (pods) → Logstash → Elasticsearch         │
│            Fluentd (aggregation) → Elasticsearch               │
│            Kibana (visualization & analysis)                   │
│                                                                 │
│  Traces:   OTEL Collector → Jaeger → Elasticsearch            │
│                                                                 │
│  APM:      Full stack correlation via Elasticsearch           │
└─────────────────────────────────────────────────────────────────┘

## Component Stack

### Layer 1: Infrastructure (IaC)
- **Terraform**: Provision infrastructure, operators, CRDs
- **Ansible**: Configure, patch, manage state

### Layer 2: Registry & Mirroring
- **Internal Registry**: Quay (Red Hat) or Harbor (CNCF)
- **Image Mirror**: Skopeo-based sync from external registries
- **Scanning**: Clair (Quay) or Trivy (Harbor)

### Layer 3: Secrets & Security
- **Vault**: HashiCorp Vault (HA with Raft storage)
- **ESO**: External Secrets Operator
- **cert-manager**: Automated certificate management
- **Rotation**: 24-hour credential rotation

### Layer 4: CI/CD Pipeline
- **Tekton**: Cloud-native CI/CD
- **Security Scanning**:
- **Trivy**: Vulnerability scanning (build-time)
- **Aqua**: Runtime security scanning & enforcement
- **SonarQube**: Code quality & security
- **Checkov**: IaC scanning
- **SBOM**: Syft (Anchore)
- **Signing**: Cosign (Sigstore)
- **Testing**: Unit, integration, E2E

### Layer 5: Runtime Security
- **Aqua Enforcer**: DaemonSet on all nodes
- Runtime image scanning
- Container drift detection
- Behavioral threat detection
- CVE blocking at runtime
- Compliance enforcement

### Layer 6: GitOps
- **ArgoCD**: Continuous delivery
- **App of Apps**: Hierarchical deployment
- **Sync Policies**: Auto-sync with validation

### Layer 7: Networking
- **Linkerd**: Service mesh (mTLS, observability)
- **Envoy Gateway**: Ingress (rate limiting, auth)
- **External DNS**: Auto DNS updates

### Layer 8: Governance
- **Kyverno**: Policy enforcement
- Image signature verification
- Resource quotas
- Security contexts
- Network policies

### Layer 9: Observability - ELK Stack

#### Metrics Collection
- **Prometheus**: Metrics scraping & storage
- **Node Exporter**: System metrics from all nodes
- CPU, memory, disk, network
- Process metrics
- Hardware sensors
- **Grafana**: Visualization & dashboards

#### Log Collection & Aggregation
- **Filebeat**: Pod-level log collection
- DaemonSet on all nodes
- Ships logs to Logstash/Elasticsearch
- Log enrichment with metadata

- **Fluentd**: Log aggregation & routing
- Buffers and batches logs
- Log filtering and transformation
- Multi-destination routing

- **Logstash**: Log processing pipeline
- Parsing and normalization
- Grok patterns for structured logs
- Enrichment with GeoIP, etc.

- **Elasticsearch**: Log storage & search
- HA cluster (3+ nodes)
- Index lifecycle management
- Hot/warm/cold architecture

- **Kibana**: Log visualization & analysis
- Dashboards and visualizations
- Log querying with KQL
- Alerting and reporting

#### Distributed Tracing
- **OTEL Collector**: Trace collection
- **Jaeger**: Trace storage & UI
- **Elasticsearch Backend**: Long-term trace storage

#### APM & Correlation
- **Unified view**: Logs + Metrics + Traces in Kibana
- **Context switching**: Jump from metrics to logs to traces
- **Alert correlation**: Cross-stack incident analysis

### Layer 10: Platform Services
- **Kafka**: Event streaming (Strimzi)
- **PostgreSQL**: Databases (CloudNativePG)
- **Redis**: Caching

## Implementation Phases

### Phase 1: Foundation (Week 1)
1. Setup internal OCI registry (Quay/Harbor)
2. Configure image mirroring
3. Deploy Vault (HA)
4. Configure External Secrets Operator

### Phase 2: CI/CD & Security (Week 2)
1. Deploy Tekton pipelines
2. Integrate Trivy scanning (build-time)
3. Deploy Aqua for runtime scanning
4. Setup SonarQube
5. Configure SBOM generation (Syft)
6. Implement Cosign signing

### Phase 3: Platform Services (Week 3)
1. Deploy cert-manager
2. Setup Linkerd service mesh
3. Deploy Envoy Gateway
4. Configure External DNS
5. Deploy Kyverno policies

### Phase 4: Observability - ELK Stack (Week 4-5)

#### Week 4: Metrics & Initial Logging
1. Deploy Prometheus Operator
2. Deploy Node Exporter (DaemonSet)
3. Configure Grafana
4. Deploy Elasticsearch cluster (HA)
5. Deploy Kibana
6. Create initial dashboards

#### Week 5: Complete Logging Pipeline
1. Deploy Filebeat (DaemonSet)
2. Deploy Fluentd aggregators
3. Deploy Logstash processing pipeline
4. Configure index templates & ILM
5. Setup Jaeger with Elasticsearch backend
6. Deploy OTEL Collector
7. Create unified dashboards in Kibana

### Phase 5: Platform Services (Week 6)
1. Deploy Kafka (Strimzi)
2. Deploy PostgreSQL (CloudNativePG)
3. Deploy Redis

### Phase 6: Sample Application (Week 7)
1. Build sample microservices
2. Create CI/CD pipelines with Aqua scanning
3. Deploy via ArgoCD
4. Validate end-to-end observability

## ELK Stack Architecture Details

### Elasticsearch Cluster
elasticsearch-master-0  (master, data)
elasticsearch-master-1  (master, data)
elasticsearch-master-2  (master, data)

### Data Flow
Application Pods
    ↓
Filebeat (sidecar/daemonset)
    ↓
Fluentd (aggregator pods)
    ↓
Logstash (processing pipeline)
    ↓
Elasticsearch (storage & indexing)
    ↓
Kibana (visualization)

### Index Strategy
- **Logs**: `logs-{namespace}-{YYYY.MM.DD}`
- **Metrics**: `metricbeat-{YYYY.MM.DD}`
- **Traces**: `jaeger-span-{YYYY.MM.DD}`
- **ILM**: 7 days hot, 30 days warm, 90 days cold, delete after 1 year

### Node Exporter Metrics
- CPU usage, load average
- Memory usage, swap
- Disk I/O, space usage
- Network traffic, errors
- Process counts
- Hardware temps (if available)

## Security Controls

### Image Security
- All images from internal registry only
- Signed with Cosign
- Scanned for CVEs at build (fail on HIGH/CRITICAL)
- **Runtime scanning with Aqua (continuous)**
- SBOM attached to every image

### Runtime Security (Aqua)
- Behavioral monitoring
- Drift detection (unauthorized changes)
- Network policy enforcement
- Runtime CVE blocking
- Malware detection
- Compliance checks

### Secret Management
- Zero hardcoded secrets
- All secrets in Vault
- Auto-rotation every 24h
- Encrypted in transit and at rest

### Network Security
- mTLS everywhere (Linkerd)
- Network policies (default deny)
- Ingress rate limiting
- DDoS protection

### Compliance
- Pod Security Standards (restricted)
- Resource quotas enforced
- Audit logging to Elasticsearch
- Policy violations blocked

## Terraform Structure
terraform/
├── modules/
│   ├── registry/          # Quay/Harbor
│   ├── vault/             # Vault HA
│   ├── tekton/            # Pipelines
│   ├── aqua/              # Runtime security
│   ├── elasticsearch/     # ES cluster
│   ├── logging/           # Filebeat, Fluentd, Logstash
│   ├── kibana/            # Kibana
│   ├── metrics/           # Prometheus, Node Exporter
│   ├── jaeger/            # Tracing
│   ├── service-mesh/      # Linkerd
│   └── kafka/             # Strimzi
├── environments/
│   ├── dev/
│   ├── staging/
│   └── prod/
└── main.tf

## Ansible Structure
ansible/
├── playbooks/
│   ├── registry-setup.yml
│   ├── vault-init.yml
│   ├── image-mirror.yml
│   ├── elasticsearch-tune.yml
│   ├── aqua-deploy.yml
│   └── backup.yml
├── roles/
│   ├── registry/
│   ├── vault/
│   ├── elasticsearch/
│   ├── logging/
│   ├── monitoring/
│   ├── aqua/
│   └── kafka/
└── inventory/

## CI/CD Pipeline Stages (with Aqua)

### Stage 1: Source
- Git clone
- Dependency check
- License scan

### Stage 2: Build
- Container build (Buildah/Kaniko)
- Multi-arch support
- Layer caching

### Stage 3: Security Scan
- Trivy: CVE scanning (build-time)
- SonarQube: Code quality
- Checkov: IaC validation

### Stage 4: Test
- Unit tests
- Integration tests
- Coverage gate (>80%)

### Stage 5: SBOM & Sign
- Generate SBOM (Syft)
- Sign image (Cosign)
- Attest build provenance

### Stage 6: Runtime Security Registration
- Register image with Aqua
- Set runtime policies
- Configure drift detection

### Stage 7: Promote
- Push to internal registry
- Update Helm chart
- Git commit (version bump)

### Stage 8: Deploy
- ArgoCD sync
- Aqua runtime enforcement starts
- Health checks
- Rollback on failure

## Observability Dashboards

### Kibana Dashboards
1. **Application Logs**: Error rates, log levels, search
2. **Infrastructure Logs**: Node logs, system events
3. **Security Logs**: Audit logs, security events, Aqua alerts
4. **APM Dashboard**: Request rates, latencies, errors
5. **Trace Analysis**: Distributed traces, span analysis

### Grafana Dashboards
1. **Cluster Overview**: CPU, memory, disk, network
2. **Node Metrics**: Per-node resource usage
3. **Pod Metrics**: Container resource usage
4. **Kafka Metrics**: Topics, lag, throughput
5. **Custom App Metrics**: Business metrics

## Next Steps

1. Update implementation plan with ELK details
2. Create Terraform modules for ELK stack
3. Create Ansible playbooks for Elasticsearch tuning
4. Setup Aqua runtime security
5. Build first pipeline with all security stages
6. Test end-to-end observability

---
**Status**: Architecture design complete with ELK stack
**Next**: Begin Phase 1 - Foundation setup
