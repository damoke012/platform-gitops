terraform {
  # 1.7+ for for_each in import blocks.
  required_version = ">= 1.7.0"

  required_providers {
    # Standalone-ESXi provider: SSH + vim-cmd, no vCenter. hashicorp/vsphere cannot be used here
    # because the free ESXi license makes the vSphere API read-only for power and reconfigure.
    esxi = {
      source  = "josenk/esxi"
      version = "= 1.10.3"
    }
  }

  # State lives on ocp-svc, outside the repo. The path is passed at init:
  #   terraform init -backend-config="path=$TF_STATE_PATH"
  backend "local" {}
}
