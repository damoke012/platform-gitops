#!/usr/bin/env python3
"""Refuse any Terraform plan for the OCP control-plane VMs that is not one of:

  * a pure import (first run, or after a VM is rebuilt), or
  * an in-place update touching only numvcpus / memsize / power.

Why it is this strict: josenk/esxi power-cycles the guest on *every* in-place update, whatever
attribute changed, and rewrites .vmx keys (firmware, guestOS, NICs, SCSI disks) to match config.
On a three-member etcd, an unplanned power cycle of two nodes is a full outage, and a wrong
firmware value is an unbootable control plane. So any update is treated as disruptive and handed
to rolling-apply.sh, one node at a time.

Usage:
  plan_gate.py plan.json                    # whole plan; prints summary JSON
  plan_gate.py plan.json --expect-node cp-2 # per-node re-plan inside rolling-apply.sh

Exit 0 = allowed (summary on stdout). Exit 1 = refused (reasons on stderr).
"""
import argparse
import json
import sys

RESOURCE_TYPE = "esxi_guest"
ALLOWED_UPDATE_ATTRS = {"numvcpus", "memsize", "power"}
# Computed by the provider; may show as unknown after an update without being a config change.
IGNORED_COMPUTED = {"id", "ip_address"}


def _changed_attrs(change):
    before = change.get("before") or {}
    after = change.get("after") or {}
    unknown = change.get("after_unknown") or {}
    keys = set(before) | set(after) | set(unknown)
    changed = []
    for k in sorted(keys):
        if k in IGNORED_COMPUTED:
            continue
        if before.get(k) != after.get(k) or unknown.get(k) is True:
            changed.append(k)
    return changed


def evaluate(plan, expect_node=None):
    errors, imports, disruptive = [], [], []
    nodes = ((plan.get("output_changes") or {}).get("nodes") or {}).get("after") or {}

    for rc in plan.get("resource_changes", []):
        addr = rc.get("address")
        change = rc.get("change") or {}
        actions = change.get("actions") or []
        if rc.get("mode") != "managed":
            continue
        if rc.get("type") != RESOURCE_TYPE:
            if actions != ["no-op"]:
                errors.append(f"{addr}: unexpected resource type with actions {actions}")
            continue

        key = rc.get("index")
        if change.get("importing"):
            imports.append(key)
        if actions == ["no-op"]:
            continue
        if actions != ["update"]:
            errors.append(
                f"{addr}: action {actions} is never allowed. This pipeline only imports and "
                "resizes; creating, replacing or destroying a control plane is done by hand."
            )
            continue

        changed = _changed_attrs(change)
        bad = [k for k in changed if k not in ALLOWED_UPDATE_ATTRS]
        if bad:
            errors.append(
                f"{addr}: update touches {bad}; only {sorted(ALLOWED_UPDATE_ATTRS)} may change. "
                "If this is drift from import, fix control-planes.tf to match the VM."
            )
            continue
        node = nodes.get(key)
        if not node:
            errors.append(f"{addr}: no entry for {key!r} in output.nodes")
            continue
        before = change.get("before") or {}
        after = change.get("after") or {}
        disruptive.append({
            "key": key,
            "vmid": str(node["vmid"]),
            "ip": node["ip"],
            "changed": changed,
            "numvcpus": after.get("numvcpus"),
            "memsize": after.get("memsize"),
            "from": {k: before.get(k) for k in changed},
        })

    if imports and disruptive:
        errors.append(
            f"imports {imports} and updates {[d['key'] for d in disruptive]} in one plan. "
            "Push the import with sizes matching reality first, then the resize."
        )
    if expect_node is not None:
        keys = [d["key"] for d in disruptive]
        if keys != [expect_node] or imports:
            errors.append(
                f"per-node plan for {expect_node} contains updates {keys} and imports {imports}; "
                f"expected exactly one update to {expect_node}"
            )

    return {"imports": imports, "disruptive": disruptive}, errors


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("plan_json")
    ap.add_argument("--expect-node")
    args = ap.parse_args()
    with open(args.plan_json) as f:
        plan = json.load(f)
    summary, errors = evaluate(plan, args.expect_node)
    if errors:
        for e in errors:
            print(f"REFUSED: {e}", file=sys.stderr)
        sys.exit(1)
    json.dump(summary, sys.stdout, indent=2)
    print()


if __name__ == "__main__":
    main()
