variable "vm_name" {
  type        = string
  description = "Name of the Windows Server 2025 VM"
}

variable "vm_memory_mb" {
  type        = number
  description = "Startup memory in MB"
  default     = 8192
}

variable "vm_cpu_count" {
  type        = number
  description = "Number of vCPUs"
  default     = 4
}

variable "windows_iso_path" {
  type        = string
  description = "Full path to the Windows Server 2025 ISO"
}

variable "vhd_path" {
  type        = string
  description = "Full path to the VM's VHDX file"
}

variable "virtual_switch_name" {
  type        = string
  description = "Name of the Hyper-V virtual switch"
}

variable "admin_username" {
  type        = string
  description = "Local Administrator username"
}

variable "admin_password" {
  type        = string
  description = "Local Administrator password"
  sensitive   = true
}

variable "vhd_size_gb" {
  type = number
  description = "Size of the VHDX in GB"
  default = 80
}

variable "autounattend_iso_path" {
  type = string
  description = "Path to ISO containing autounattend.xml for unattended setup"
}