# Session 006: Kafka Platform Engineering - GitOps Deployment

**Date**: 2025-10-28
**Duration**: ~4 hours
**Focus**: Deploy production-ready Kafka cluster with GitOps workflow for SRE interview preparation
**Role**: JP Morgan Chase - SRE III Kafka Platform Engineering

## Objective

Deploy Strimzi-based Kafka cluster in airgapped OpenShift environment using GitOps methodology, with Kafka    
UI for management, sample applications for testing, and preparation for SRE operational scenarios
including partition rebalancing, consumer group management, and failure recovery.

## Summary

Successfully migrated Kafka deployment from manual operations to full GitOps workflow using ArgoCD.
Overcame airgapped cluster challenges by distributing container images via SSH. Implemented
production-ready Kafka 4.0 with KRaft mode (no ZooKeeper), separated controller and broker node pools, and    
enforced worker-only scheduling with node taints and affinity rules.

## Work Completed

### 1. Image Distribution for Airgapped Cluster

**Challenge**: Worker nodes cannot pull images from external registries (quay.io, docker.io)

**Solution**: Bastion host image distribution workflow

```bash
# On ocp-svc (bastion host with internet access)
podman pull quay.io/strimzi/operator:0.48.0
podman pull quay.io/strimzi/kafka:0.48.0-kafka-4.0.0

# Save images to tar files
podman save quay.io/strimzi/operator:0.48.0 -o /tmp/strimzi-operator.tar
podman save quay.io/strimzi/kafka:0.48.0-kafka-4.0.0 -o /tmp/strimzi-kafka-4.0.tar

# Distribute to all worker nodes
for node in ocp-w-1 ocp-w-2 ocp-w-3; do
   scp /tmp/strimzi-operator.tar core@${node}.lab.ocp.lan:/tmp/
   scp /tmp/strimzi-kafka-4.0.tar core@${node}.lab.ocp.lan:/tmp/
   ssh core@${node}.lab.ocp.lan "sudo podman load -i /tmp/strimzi-operator.tar"
   ssh core@${node}.lab.ocp.lan "sudo podman load -i /tmp/strimzi-kafka-4.0.tar"
done

Images deployed:
- quay.io/strimzi/operator:0.48.0 (442 MB)
- quay.io/strimzi/kafka:0.48.0-kafka-4.0.0 (687 MB)

2. GitOps Directory Structure

Created following established repository pattern:

argocd/platform/
├── kafka-app.yaml                      # ArgoCD Application for Kafka cluster
├── kafka-ui-app.yaml                   # ArgoCD Application for Kafka UI
├── kafka-sample-apps-app.yaml          # ArgoCD Application for sample apps
└── kafka/
   ├── base/
   │   ├── kustomization.yaml
   │   ├── namespace.yaml
   │   ├── strimzi-operator.yaml       # Operator subscription (OLM)
   │   ├── kafka-metrics-configmap.yaml
   │   ├── kafka-controller-nodepool.yaml
   │   ├── kafka-broker-nodepool.yaml
   │   └── kafka-cluster.yaml
   ├── kafka-ui/
   │   ├── kustomization.yaml
   │   ├── deployment.yaml
   │   ├── service.yaml
   │   └── route.yaml
   └── sample-apps/
         ├── kustomization.yaml
         ├── test-topic.yaml
         ├── producer-deployment.yaml
         └── consumer-deployment.yaml

3. Kafka Cluster Architecture

KRaft Mode (Kafka without ZooKeeper)

Controller Node Pool (3 replicas):
- Role: Cluster metadata management, leader election
- Storage: 10Gi persistent volume per controller (nfs-harbor)
- Resources: 1Gi memory, 250m-500m CPU
- Affinity: Worker nodes only

Broker Node Pool (3 replicas):
- Role: Message handling, partition leadership
- Storage: 20Gi persistent volume per broker (nfs-harbor)
- Resources: 2Gi memory, 500m-1000m CPU
- Affinity: Worker nodes only

Configuration Highlights:
- Kafka 4.0.0 with KRaft mode
- Replication factor: 3
- Min in-sync replicas: 2
- 7-day retention
- JMX Prometheus metrics
- Entity operator for topic/user management

4. Kafka UI Deployment

Access: https://kafka-ui.apps.lab.ocp.lan

Features:
- Topic management and visualization
- Consumer group monitoring
- Broker health metrics
- Message browsing
- Configuration management

5. Sample Applications

Test Topic: 3 partitions, 3 replicas, 7-day retention

Producer: Generates JSON messages every 5 seconds
Consumer: 2 replicas in consumer group for rebalancing practice

Key Learnings

Airgapped Deployment

- SSH-based image distribution from bastion host
- ImagePullPolicy: IfNotPresent critical for disconnected environments
- Harbor registry attempted but bypassed due to access complexity

Strimzi 0.48.0 Changes

- KafkaNodePool requirement (deprecated simple replicas field)
- Separate controller and broker roles
- KRaft benefits: No ZooKeeper, faster metadata operations

Control Plane Protection

- Applied NoSchedule taints to control plane nodes
- Node affinity rules in KafkaNodePool specs
- All Kafka workloads on worker nodes only

GitOps Workflow

- App of Apps pattern for automatic discovery
- Automated sync with prune and selfHeal
- First proper GitOps deployment in platform-gitops repo

Files Created

Total: 18 files, ~600 lines of YAML

- 3 ArgoCD Application manifests
- 7 Kafka base manifests
- 4 Kafka UI manifests
- 4 Sample app manifests

Next Steps for Interview Preparation

Practice Scenarios

1. Partition Rebalancing: Add brokers, trigger reassignment
2. Consumer Group Rebalancing: Scale consumers, observe partition assignment
3. Broker Failure Simulation: Delete broker pod, monitor ISR recovery
4. Topic Configuration: Modify partitions, retention, min.insync.replicas
5. Monitoring Setup: Prometheus ServiceMonitor, Grafana dashboards

Production Checklist

- Migrate to Harbor registry
- Configure RBAC with KafkaUser CRDs
- Enable TLS for all listeners
- Implement network policies
- Set up Prometheus monitoring
- Create Grafana dashboards
- Configure PodDisruptionBudgets
- Document disaster recovery procedures

Interview Topics Mastered

Kafka Core:
- Partition leadership and ISR
- Replication factor vs min.insync.replicas
- Producer acknowledgments (acks=0/1/all)
- Consumer offset management

Operations:
- Partition reassignment
- Consumer group rebalancing (sticky, range, cooperative)
- Monitoring: under-replicated partitions, consumer lag
- Capacity planning

Strimzi vs Confluent:
- Core operations identical across distributions
- Strimzi: Declarative K8s resources
- Confluent: Imperative configuration
- Transferable skills: partition management, rebalancing, troubleshooting

---
Session End: Kafka platform deployed via GitOps ✅

Progress: Session 006 complete - Ready for SRE operational practice

Next Session: Operational scenarios and monitoring setup
