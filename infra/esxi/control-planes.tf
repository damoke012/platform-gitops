# ─────────────────────────────────────────────────────────────────────────────────────────────
# THIS IS THE FILE YOU EDIT TO RESIZE A CONTROL PLANE.
#
# Change numvcpus / memsize_mb for one node, push to main. The pipeline drains the node, shuts
# it down gracefully, lets Terraform rewrite the .vmx and power it on, then waits for the node
# and etcd to come back before it uncordons. More than one node in a push is handled serially.
#
# Values must match reality before the first run (import only). Sizes as of 2026-11-08:
# cp-3 was resized by hand to 8/24; cp-1 (rebuilt as cp-1-rp) and cp-2 are 4/16.
#
# numvcpus must be divisible by the VM's cpuid.coresPerSocket; rolling-apply.sh checks this
# against the .vmx before shutting anything down.
# ─────────────────────────────────────────────────────────────────────────────────────────────
locals {
  control_planes = {
    "cp-1" = { vmid = "140", guest_name = "cp-1-rp", ip = "192.168.22.201", numvcpus = 4, memsize_mb = 16384 }
    "cp-2" = { vmid = "93", guest_name = "ocp-cp-2", ip = "192.168.22.202", numvcpus = 4, memsize_mb = 16384 }
    "cp-3" = { vmid = "94", guest_name = "ocp-cp-3", ip = "192.168.22.203", numvcpus = 8, memsize_mb = 24576 }
  }
}

import {
  for_each = local.control_planes
  to       = esxi_guest.cp[each.key]
  id       = each.value.vmid # the provider imports by numeric vmid, not by name
}

resource "esxi_guest" "cp" {
  for_each = local.control_planes

  guest_name = each.value.guest_name
  disk_store = var.disk_store
  numvcpus   = each.value.numvcpus
  memsize    = each.value.memsize_mb
  power      = "on"

  lifecycle {
    # These VMs were built by the UPI install and a hand rebuild, not by Terraform. Terraform owns
    # exactly three attributes: numvcpus, memsize, power. Everything else is ignored so that an
    # imported value that differs from this file can never become an in-place "fix" (wrong
    # firmware or NIC on a control plane is an unbootable node) or a ForceNew replacement.
    # scripts/plan_gate.py enforces the same allowlist on the plan, independently of this block.
    prevent_destroy = true
    ignore_changes = [
      guest_name, disk_store, resource_pool_name, boot_disk_type, boot_disk_size, boot_firmware,
      guestos, virthwver, network_interfaces, virtual_disks, notes, guestinfo,
      clone_from_vm, ovf_source, host_ovf, ovf_properties, ovf_properties_timer,
      guest_startup_timeout, guest_shutdown_timeout,
    ]
  }
}

output "nodes" {
  description = "Read by plan_gate.py to map a changed resource to its vmid and node IP."
  value       = local.control_planes
}
