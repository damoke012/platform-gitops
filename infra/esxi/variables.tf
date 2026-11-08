variable "esxi_hostname" {
  description = "Standalone ESXi host carrying the OCP VMs."
  type        = string
  default     = "192.168.1.144"
}

variable "esxi_username" {
  type    = string
  default = "root"
}

variable "disk_store" {
  description = "Datastore holding the VMs. Required by the provider schema; ignored after import."
  type        = string
  default     = "datastore1"
}
