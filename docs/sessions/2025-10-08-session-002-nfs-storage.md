# Session 002: NFS Storage Configuration and Troubleshooting

**Date**: 2025-10-08
**Duration**: ~2 hours
**Focus**: Configure NFS dynamic storage provisioning for Harbor registry

## Objective

Set up persistent storage infrastructure to support Harbor OCI registry deployment using NFS-backed dynamic
provisioning.

## Summary

Successfully configured NFS storage backend with dynamic provisioning capability. Encountered and resolved complex
read-only filesystem issues through systematic troubleshooting of NFS exports, SELinux contexts, OpenShift SCCs, and
  volume mount configurations.

## Environment Status

**Before**:
- No StorageClass available
- No persistent storage backend
- Cluster unable to provision PVs dynamically

**After**:
- ✅ NFS server configured on ocp-svc (192.168.22.1)
- ✅ NFS Subdir External Provisioner deployed
- ✅ StorageClass `nfs-harbor` created and set as default
- ✅ Dynamic PV provisioning working
- ✅ Custom SCC created for NFS volume access

## Work Completed

### 1. NFS Server Configuration

**Created NFS export directories**:
```bash
mkdir -p /exports/harbor/{registry,database,redis,trivy}
chown -R nobody:nobody /exports/harbor
chmod -R 777 /exports/harbor

Configured SELinux contexts:
semanage fcontext -a -t nfs_t "/exports/harbor(/.*)?"
restorecon -Rv /exports/harbor

Configured NFS exports (/etc/exports):
/exports/harbor 192.168.22.0/24(rw,sync,no_root_squash,no_all_squash)
/exports/harbor/registry 192.168.22.0/24(rw,sync,no_root_squash,no_all_squash)
/exports/harbor/database 192.168.22.0/24(rw,sync,no_root_squash,no_all_squash)
/exports/harbor/redis 192.168.22.0/24(rw,sync,no_root_squash,no_all_squash)
/exports/harbor/trivy 192.168.22.0/24(rw,sync,no_root_squash,no_all_squash)

Key Learning: Must export parent directory (/exports/harbor) for dynamic provisioner to create subdirectories, not
just the subdirectories themselves.

2. Helm Installation

Installed Helm 3.19.0 for managing Kubernetes applications:
# System installed via dnf
helm version

3. NFS Provisioner Deployment

Added Helm repository:
helm repo add nfs-subdir-external-provisioner \
  https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/

Created values file (/tmp/nfs-provisioner-values.yaml):
nfs:
  server: 192.168.22.1
  path: /exports/harbor
  mountOptions:
    - nfsvers=4.1
    - rw
    - hard
    - intr
storageClass:
  name: nfs-harbor
  defaultClass: true
  reclaimPolicy: Delete
  archiveOnDelete: false

Installed provisioner:
helm install nfs-subdir-external-provisioner \
  nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
  --namespace nfs-provisioner \
  --values /tmp/nfs-provisioner-values.yaml

4. Security Context Constraints (SCC)

Created custom SCC for NFS volume access (/tmp/nfs-provisioner-scc.yaml):
apiVersion: security.openshift.io/v1
kind: SecurityContextConstraints
metadata:
  name: nfs-provisioner-scc
allowHostDirVolumePlugin: false
allowHostIPC: false
allowHostNetwork: false
allowHostPID: false
allowHostPorts: false
allowPrivilegeEscalation: true
allowPrivilegedContainer: false
fsGroup:
  type: RunAsAny
runAsUser:
  type: RunAsAny
seLinuxContext:
  type: MustRunAs
supplementalGroups:
  type: RunAsAny
volumes:
- configMap
- downwardAPI
- emptyDir
- persistentVolumeClaim
- projected
- secret
- nfs

Applied SCC:
oc apply -f /tmp/nfs-provisioner-scc.yaml
oc adm policy add-scc-to-user nfs-provisioner-scc \
  system:serviceaccount:nfs-provisioner:nfs-subdir-external-provisioner

5. Troubleshooting Read-Only Filesystem

Problem: NFS provisioner consistently failed with "read-only file system" errors.

Troubleshooting Steps:

1. Verified NFS write access from worker nodes ✅
ssh core@192.168.22.201 "sudo mount -t nfs 192.168.22.1:/exports/harbor/registry /mnt/test && sudo touch 
/mnt/test/writetest"
1. Result: SUCCESS - NFS writes work from cluster network
2. Checked SELinux contexts ✅
ls -laZ /exports/harbor
# All directories showed correct nfs_t context
3. Verified NFS export options ✅
exportfs -v
# Showed rw,no_root_squash,no_all_squash
4. Discovered Helm chart issue: Chart was creating PVC instead of direct NFS mount
5. Patched deployment to use direct NFS volume:
oc patch deployment nfs-subdir-external-provisioner -n nfs-provisioner --type=json -p='[
  {
    "op": "replace",
    "path": "/spec/template/spec/volumes/0",
    "value": {
      "name": "nfs-subdir-external-provisioner-root",
      "nfs": {
        "server": "192.168.22.1",
        "path": "/exports/harbor"
      }
    }
  }
]'
6. Added UID/GID to pod security context:
oc patch deployment nfs-subdir-external-provisioner -n nfs-provisioner --type=json -p='[
  {
    "op": "add",
    "path": "/spec/template/spec/securityContext/fsGroup",
    "value": 1000750000
  },
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/securityContext/runAsUser",
    "value": 1000750000
  }
]'
7. ROOT CAUSE IDENTIFIED: Parent directory /exports/harbor was NOT in NFS exports
  - Only subdirectories were exported
  - Provisioner needs parent directory to create new subdirectories dynamically
8. Solution: Added parent directory to exports:
echo '/exports/harbor 192.168.22.0/24(rw,sync,no_root_squash,no_all_squash)' >> /etc/exports
exportfs -ra

Result: ✅ Dynamic provisioning working successfully!

Verification

Test PVC created:
oc get pvc -n harbor
NAME       STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS
test-pvc   Bound    pvc-f277daf2-0dca-4beb-9328-8f0e5a650856   1Gi        RWO            nfs-harbor

PV automatically created:
oc get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM
pvc-f277daf2-0dca-4beb-9328-8f0e5a650856   1Gi        RWO            Delete           Bound    harbor/test-pvc

Directory created on NFS server:
ls -la /exports/harbor/
drwxrwxrwx. 2 1000750000 root 6 Oct  7 22:07 harbor-test-pvc-pvc-f277daf2-0dca-4beb-9328-8f0e5a650856

Configuration Files Created

- /tmp/nfs-provisioner-scc.yaml - Custom SCC for NFS access
- /tmp/nfs-provisioner-values.yaml - Helm values for provisioner
- /etc/exports - NFS server export configuration (modified)

Key Learnings

Production Best Practices

1. NFS Export Hierarchy:
  - Export parent directory for dynamic provisioners to create subdirectories
  - Can also export subdirectories for static PVs
2. OpenShift Security:
  - Custom SCCs required for NFS volumes
  - Must explicitly allow nfs volume type
  - UID/GID must match between NFS ownership and pod security context
3. SELinux in Production:
  - Use nfs_t context for NFS exports: semanage fcontext -a -t nfs_t
  - Always run restorecon after setting contexts
  - Check ausearch -m avc for denials
4. Helm Chart Limitations:
  - Some Helm charts create unnecessary PVC layers
  - May need to patch deployments post-installation
  - Always verify actual deployed resources match expectations
5. Troubleshooting Methodology:
  - Test NFS access from worker nodes directly
  - Check SELinux contexts and denials
  - Verify export options with exportfs -v
  - Examine pod security contexts and SCCs
  - Check actual mounted volume type (PVC vs direct NFS)

Next Steps

Immediate (Session 003)

1. Deploy Harbor registry using Helm
2. Configure TLS certificates
3. Create Harbor projects for different image types
4. Test image push/pull

Upcoming

1. Day 2: Deploy HashiCorp Vault (HA with Raft storage)
2. Day 3: External Secrets Operator integration
3. Day 4-5: Tekton CI/CD pipelines with security scanning
4. Week 2: ELK stack deployment

Commands Reference

Check storage resources

oc get storageclass
oc get pv
oc get pvc -A

NFS provisioner status

oc get pods -n nfs-provisioner
oc logs -n nfs-provisioner deployment/nfs-subdir-external-provisioner

NFS server management

exportfs -v                    # Show active exports
exportfs -ra                   # Re-export all
showmount -e localhost         # Show export list
systemctl restart nfs-server   # Restart NFS

Test NFS write from worker

ssh core@192.168.22.201 "sudo mkdir -p /mnt/test && sudo mount -t nfs 192.168.22.1:/exports/harbor /mnt/test && sudo
  touch /mnt/test/writetest && sudo umount /mnt/test"

Issues Encountered

Issue #1: No Storage Classes Available

- Error: oc get storageclass returned no resources
- Root Cause: No storage backend configured in cluster
- Resolution: Deployed NFS provisioner with dynamic PV creation
- Time to Resolve: 15 minutes

Issue #2: NFS Provisioner Read-Only Filesystem

- Error: mkdir: read-only file system
- Root Cause: Parent directory /exports/harbor not exported, only subdirectories
- Resolution: Added parent directory to /etc/exports
- Time to Resolve: 90 minutes (extensive troubleshooting)
- Key Diagnostic: Comparing showmount -e output with mounted NFS path

Issue #3: SCC Blocking NFS Volumes

- Error: Pod creation forbidden due to NFS volume type
- Root Cause: Default OpenShift SCCs don't allow NFS volumes
- Resolution: Created custom SCC with volumes: [nfs]
- Time to Resolve: 20 minutes

Issue #4: UID Mismatch

- Error: Permission denied despite RW NFS exports
- Root Cause: Pod running as UID without explicit setting, NFS owned by different UID
- Resolution: Added runAsUser: 1000750000 and fsGroup: 1000750000
- Time to Resolve: 10 minutes

Files Modified

On ocp-svc server:

- /etc/exports - Added Harbor NFS exports
- Created /exports/harbor/ directory structure
- SELinux contexts applied to /exports/harbor/

In OpenShift:

- Created namespace: nfs-provisioner
- Created namespace: harbor
- Created SCC: nfs-provisioner-scc
- Created StorageClass: nfs-harbor (via Helm)
- Deployed: NFS Subdir External Provisioner

Cluster State

Namespaces:

- openshift-gitops - ArgoCD (from Session 001)
- nfs-provisioner - NFS dynamic provisioner
- harbor - Prepared for Harbor deployment

Storage:

- Default StorageClass: nfs-harbor
- NFS Server: 192.168.22.1:/exports/harbor
- Provisioner: cluster.local/nfs-subdir-external-provisioner

Operators:

- OpenShift GitOps Operator v1.18.0

---Session End: NFS storage infrastructure complete and verified ✅
