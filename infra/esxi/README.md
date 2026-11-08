# infra/esxi — OCP control-plane VMs as code

> **UNVALIDATED (2026-11-08).** `terraform validate`, `fmt` and the gate unit tests pass. Nothing
> here has been run against ESXi or the cluster. The first real run is the import. Do it as a
> plan-only dispatch, and only when the preconditions below hold.

Terraform owns three attributes of `cp-1`, `cp-2` and `cp-3` on the standalone ESXi host
`192.168.1.144`: **numvcpus, memsize, power**. Everything else about the VMs is ignored on purpose:
disks, NICs, firmware, guestOS and the name.

## Resizing a control plane

1. Edit `numvcpus` / `memsize_mb` for the node in [`control-planes.tf`](control-planes.tf).
2. Push to `main`. Do one node per push unless you have a reason. The pipeline runs nodes
   serially either way.
3. Watch `homelab-esxi` in Actions. Expect 30–90 min per node on the current datastore.

For each node the pipeline runs [`scripts/rolling-apply.sh`](scripts/rolling-apply.sh):

- preflight: 3/3 control planes Ready, etcd 3/3, no quorum override, operators settled.
- `.vmx` checks, then a `.vmx` backup.
- cordon + drain.
- **graceful** shutdown.
- a targeted plan, re-gated, then apply. The provider rewrites `.vmx` and powers the VM on.
- verify size on ESXi, wait for Ready, etcd 3/3 and operators settled.
- uncordon.

On any failure it stops and leaves the node cordoned.

Rollback is the same motion: push the old values. If the VM will not boot, restore
`<vm>.vmx.pre-tf-<timestamp>` on the datastore, then run `vim-cmd vmsvc/reload <vmid>`.

## Why it is built this way

| Constraint | Consequence |
|---|---|
| Free ESXi license: the vSphere API cannot power or reconfigure VMs | `hashicorp/vsphere` is out. `josenk/esxi` 1.10.3 works over SSH + `vim-cmd`. |
| The provider power-cycles the guest on **any** in-place update, with a 20 s default shutdown then a hard power-off | The pipeline drains and shuts down first. Any update counts as disruptive. Timeouts are in `ignore_changes`, so changing one can't trigger a power cycle. |
| The provider rewrites firmware/guestOS/NIC keys and strips SCSI disks other than `scsi0:0` | Those attributes are in `ignore_changes`. [`plan_gate.py`](scripts/plan_gate.py) refuses any plan touching anything but the three owned attributes. `rolling-apply.sh` refuses VMs with extra SCSI disks. |
| ForceNew attributes (`disk_store`, `guest_name`, `boot_disk_type`, …) would mean replacing a control plane | `prevent_destroy`, `ignore_changes`, and the gate refuses any create/delete/replace. |
| 3-member etcd. On 2026-11-08 a single control-plane drop at 2/3 was a full outage (issue 005 in AiChohort) | Preflight refuses unless etcd is 3/3 with no override. The etcd-guard PDB stops the drain if quorum is already at risk. One node at a time. |
| Lab not reachable from GitHub-hosted runners | Self-hosted runner on ocp-svc, label `homelab-ocp-svc`. Credentials stay on ocp-svc, not in GitHub secrets. |

## What this does not do

- **Create the cluster or any VM.** A rebuild like `cp-1-rp` is still by hand, then imported
  (add the entry here with the new vmid and push). Building a new OCP node from Terraform means
  scripting the RHCOS install + ignition + CSR approval. That is a separate piece of work.
- Workers, `svc` (VM 84), datastore layout, or ESXi host config.
- Fix the 7–8 s etcd fsync. More vCPU/RAM may not help a single spinning datastore.
- Check that ESXi has the CPU/RAM to back the new sizes. Check host headroom before pushing.
- Hot-add. Every change goes through a power-off, so `vcpu.hotadd` / `mem.hotadd` don't matter here.

## Bootstrap (once, on ocp-svc)

1. **Repo visibility.** `platform-gitops` is public. GitHub advises against self-hosted runners on
   public repos: a fork PR that adds its own `pull_request` workflow can run on this runner once
   approved. Before registering the runner, either make the repo private, or set *Settings →
   Actions → Fork pull request workflows* to require approval for all outside contributors and
   never approve one blindly.
2. **Runner user.** Create a non-root `ghrunner` user. Give it:
   - a copy of the ESXi password at `/etc/homelab-iac/esxi.pw`, owned by it, mode `0400`.
   - a kubeconfig able to cordon/drain and read etcd/CO status. Copy the admin kubeconfig to
     `/etc/homelab-iac/kubeconfig` (`0400`) unless you build a narrower SA.
   - `/var/lib/homelab-iac/esxi/`, which holds the state. Back this directory up; it is the only copy.
   - `oc`, `jq`, `sshpass`, `python3`, `unzip`, and outbound HTTPS to github.com,
     releases.hashicorp.com and registry.terraform.io.
   - an ESXi host key: `ssh-keyscan 192.168.1.144 >> ~ghrunner/.ssh/known_hosts`, checked
     against the host's fingerprint. `rolling-apply.sh` uses `StrictHostKeyChecking=yes`.
3. **Register the runner** (*Settings → Actions → Runners → New self-hosted runner*) with labels
   `self-hosted,linux,homelab-ocp-svc`, and install it as a service under `ghrunner`. In the
   runner directory's `.env`:
   ```
   ESXI_PASSWORD_FILE=/etc/homelab-iac/esxi.pw
   KUBECONFIG=/etc/homelab-iac/kubeconfig
   TF_STATE_PATH=/var/lib/homelab-iac/esxi/terraform.tfstate
   ESXI_HOST=192.168.1.144
   ```
4. **Environment** `homelab` (*Settings → Environments*). Add yourself as a required reviewer if
   you want a click between push and apply. Without one, push = apply.
5. **First run = import only.** Confirm on ESXi that the vmids, names and sizes in
   `control-planes.tf` match: `vim-cmd vmsvc/getallvms`, `vim-cmd vmsvc/get.config <id>`. Then
   dispatch `homelab-esxi` with `mode=plan`. The plan must show three imports and no changes. If
   it shows an update, fix the file to match the VM; do not let Terraform "correct" the VM. Then
   dispatch `mode=apply` on main. That writes state and touches no VM.
6. Only then push a resize.

## Preconditions that do not hold today (2026-11-08)

- etcd is not 3/3, and the quorum override is still set. Preflight will refuse every resize
  until cp-1-rp joins and the override is removed. That refusal is correct.
- `localhost-0` / ocp-svc reachability is intermittent. A queued job waits for the runner for up
  to 24 h and then runs against whatever state the cluster is in. Preflight is what makes that
  safe.
