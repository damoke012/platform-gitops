#!/usr/bin/env bash
# Resize OCP control-plane VMs one at a time, never below quorum.
#
#   rolling-apply.sh gate.json
#
# For each node listed under .disruptive in gate.json (output of plan_gate.py):
#   1. cluster preflight: 3/3 control planes Ready, 3/3 etcd pods Ready, no quorum override,
#      etcd + kube-apiserver operators Available and not Degraded
#   2. .vmx preflight on ESXi: no SCSI disks the provider would strip, coresPerSocket divides
#      the new vCPU count; back the .vmx up
#   3. cordon + drain (etcd-guard PDB blocks this if quorum is already at risk: that is intended)
#   4. graceful guest shutdown via VMware Tools; NO hard power-off fallback
#   5. targeted re-plan, re-gated with --expect-node, then apply (provider edits .vmx, powers on)
#   6. verify the VM's numCPU/memoryMB on ESXi, wait for node Ready, etcd 3/3, operators settled
#   7. uncordon, then the next node
#
# On any failure it stops and leaves the node cordoned. A half-resized control plane is for a human.
#
# Runner env (from the runner's .env, not GitHub secrets):
#   ESXI_PASSWORD_FILE  KUBECONFIG  ESXI_HOST (default 192.168.1.144)
set -euo pipefail

GATE_JSON="${1:?usage: rolling-apply.sh gate.json}"
HERE="$(cd "$(dirname "$0")" && pwd)"
TF="$HERE/tf.sh"
ESXI_HOST="${ESXI_HOST:-192.168.1.144}"
: "${ESXI_PASSWORD_FILE:?}" "${KUBECONFIG:?}"

DRAIN_TIMEOUT="${DRAIN_TIMEOUT:-15m}"
SHUTDOWN_TIMEOUT_S="${SHUTDOWN_TIMEOUT_S:-1200}"
# Slow datastore: etcd fsync measured at 7-8 s on 2026-11-08. Boot and rejoin are slow.
READY_TIMEOUT_S="${READY_TIMEOUT_S:-2700}"
ETCD_TIMEOUT_S="${ETCD_TIMEOUT_S:-2700}"

log() { printf '%s  %s\n' "$(date -u +%H:%M:%SZ)" "$*"; }
die() { log "FAIL: $*"; exit 1; }

esxi() {
  # -n: never let an inner ssh eat the caller's stdin.
  sshpass -f "$ESXI_PASSWORD_FILE" ssh -n -o BatchMode=no -o StrictHostKeyChecking=yes \
    -o ConnectTimeout=15 "root@$ESXI_HOST" "$@"
}

wait_until() { # wait_until <timeout_s> <description> <command...>
  local timeout=$1 desc=$2; shift 2
  local start=$SECONDS
  until "$@"; do
    (( SECONDS - start > timeout )) && die "timed out after ${timeout}s waiting for: $desc"
    sleep 20
  done
  log "ok: $desc ($(( SECONDS - start ))s)"
}

# ── cluster checks ────────────────────────────────────────────────────────────────────────────
cp_ready_count() {
  oc get nodes -l node-role.kubernetes.io/master -o json | jq '[.items[]
    | select(.spec.unschedulable != true)
    | select(any(.status.conditions[]; .type=="Ready" and .status=="True"))] | length'
}
cp_ready_count_incl_cordoned() {
  oc get nodes -l node-role.kubernetes.io/master -o json | jq '[.items[]
    | select(any(.status.conditions[]; .type=="Ready" and .status=="True"))] | length'
}
etcd_ready_count() {
  oc -n openshift-etcd get pods -l app=etcd -o json | jq '[.items[]
    | select(any(.status.conditions[]?; .type=="Ready" and .status=="True"))] | length'
}
quorum_override_set() {
  oc get etcd cluster -o json | jq -e '.spec.unsupportedConfigOverrides
    | (. // {}) | has("useUnsupportedUnsafeNonHANonProductionUnstableEtcd")' >/dev/null
}
operators_settled() {
  oc get co etcd kube-apiserver -o json | jq -e 'all(.items[]; .status.conditions as $c
    | any($c[]; .type=="Available"   and .status=="True")
    and any($c[]; .type=="Degraded"    and .status=="False")
    and any($c[]; .type=="Progressing" and .status=="False"))' >/dev/null
}
etcd_three()      { [[ "$(etcd_ready_count)" == 3 ]]; }
node_ready()      { oc get node "$1" -o json | jq -e 'any(.status.conditions[]; .type=="Ready" and .status=="True")' >/dev/null; }

preflight_cluster() {
  oc whoami >/dev/null || die "API unreachable"
  quorum_override_set && die "etcd quorum override is set; finish 3/3 and remove it first"
  [[ "$(cp_ready_count)" == 3 ]] || die "need 3 Ready, schedulable control planes; have $(cp_ready_count)"
  etcd_three || die "need 3 Ready etcd pods; have $(etcd_ready_count)"
  operators_settled || die "etcd / kube-apiserver operators not Available+settled"
  log "ok: cluster preflight (3 CP Ready, etcd 3/3, no override, operators settled)"
}

node_for_ip() {
  oc get nodes -o json | jq -r --arg ip "$1" '.items[]
    | select(any(.status.addresses[]; .type=="InternalIP" and .address==$ip)) | .metadata.name'
}

# ── ESXi checks ───────────────────────────────────────────────────────────────────────────────
vmx_path() { # "[datastore1] ocp-cp-2/ocp-cp-2.vmx" -> /vmfs/volumes/datastore1/ocp-cp-2/ocp-cp-2.vmx
  esxi "vim-cmd vmsvc/get.config $1" \
    | sed -nE 's/.*vmPathName = "\[([^]]+)\] ([^"]+)".*/\/vmfs\/volumes\/\1\/\2/p' | head -1
}
power_state() { esxi "vim-cmd vmsvc/power.getstate $1" | tail -1; }
powered_off() { [[ "$(power_state "$1")" == "Powered off" ]]; }
powered_on()  { [[ "$(power_state "$1")" == "Powered on" ]]; }

preflight_vmx() { # vmid vmx numvcpus
  local vmid=$1 vmx=$2 want_cpu=$3 extra cps
  [[ -n "$vmx" ]] || die "vm $vmid: could not resolve .vmx path"
  # The provider deletes every scsiX:Y.* line except scsi0:0 and scsi0:7 on update.
  extra="$(esxi "grep -E '^scsi[0-9]+:[0-9]+\.' '$vmx' | grep -vE '^scsi0:(0|7)\.' || true")"
  [[ -z "$extra" ]] || die "vm $vmid has SCSI devices the provider would strip:
$extra"
  cps="$(esxi "sed -nE 's/^cpuid\.coresPerSocket = \"([0-9]+)\"/\1/p' '$vmx'")"
  if [[ -n "$cps" ]] && (( want_cpu % cps != 0 )); then
    die "vm $vmid: numvcpus $want_cpu not divisible by cpuid.coresPerSocket $cps; VM would not power on"
  fi
  esxi "cp -p '$vmx' '$vmx.pre-tf-$(date -u +%Y%m%dT%H%M%SZ)'"
  log "ok: vmx preflight, backup written next to $vmx"
}

verify_vm_size() { # vmid numvcpus memsize
  local cfg cpu mem
  cfg="$(esxi "vim-cmd vmsvc/get.config $1")"
  cpu="$(sed -nE 's/^ *numCPU = ([0-9]+),.*/\1/p' <<<"$cfg" | head -1)"
  mem="$(sed -nE 's/^ *memoryMB = ([0-9]+),.*/\1/p' <<<"$cfg" | head -1)"
  [[ "$cpu" == "$2" && "$mem" == "$3" ]] || die "vm $1 reports $cpu vCPU / $mem MB; wanted $2 / $3"
  log "ok: vm $1 is $cpu vCPU / $mem MB"
}

# ── main loop ─────────────────────────────────────────────────────────────────────────────────
count="$(jq '.disruptive | length' "$GATE_JSON")"
(( count > 0 )) || { log "nothing disruptive to apply"; exit 0; }
log "rolling apply over $count node(s): $(jq -r '[.disruptive[].key] | join(", ")' "$GATE_JSON")"

for i in $(seq 0 $((count - 1))); do
  row="$(jq -c ".disruptive[$i]" "$GATE_JSON")"
  key="$(jq -r .key <<<"$row")"; vmid="$(jq -r .vmid <<<"$row")"; ip="$(jq -r .ip <<<"$row")"
  cpu="$(jq -r .numvcpus <<<"$row")"; mem="$(jq -r .memsize <<<"$row")"
  log "──── $key (vm $vmid, $ip): $(jq -c .from <<<"$row") -> numvcpus=$cpu memsize=$mem"

  preflight_cluster
  node="$(node_for_ip "$ip")"; [[ -n "$node" ]] || die "no node with InternalIP $ip"
  vmx="$(vmx_path "$vmid")"
  preflight_vmx "$vmid" "$vmx" "$cpu"

  log "cordon + drain $node"
  oc adm cordon "$node"
  oc adm drain "$node" --ignore-daemonsets --delete-emptydir-data --force --timeout="$DRAIN_TIMEOUT"

  log "graceful shutdown vm $vmid"
  esxi "vim-cmd vmsvc/power.shutdown $vmid" || die "guest shutdown request failed (Tools not running?)"
  wait_until "$SHUTDOWN_TIMEOUT_S" "vm $vmid powered off" powered_off "$vmid"

  log "targeted plan for $key"
  "$TF" plan -input=false -lock-timeout=5m -target="esxi_guest.cp[\"$key\"]" -out="node-$key.tfplan"
  "$TF" show -json "node-$key.tfplan" > "node-$key.json"
  python3 "$HERE/plan_gate.py" "node-$key.json" --expect-node "$key" >/dev/null
  "$TF" apply -input=false -lock-timeout=5m "node-$key.tfplan"
  rm -f "node-$key.tfplan" "node-$key.json"

  powered_on "$vmid" || { log "provider left vm $vmid off; powering on"; esxi "vim-cmd vmsvc/power.on $vmid"; }
  verify_vm_size "$vmid" "$cpu" "$mem"

  wait_until "$READY_TIMEOUT_S" "node $node Ready"  node_ready "$node"
  wait_until "$ETCD_TIMEOUT_S"  "etcd 3/3 Ready"     etcd_three
  wait_until "$ETCD_TIMEOUT_S"  "operators settled"  operators_settled
  oc adm uncordon "$node"
  [[ "$(cp_ready_count_incl_cordoned)" == 3 ]] || die "control-plane count dropped after $key"
  log "done: $key"
done
log "rolling apply complete"
