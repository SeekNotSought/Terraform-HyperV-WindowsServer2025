
resource "hyper_vhd" "win2025_disk" {
  path = var.vhd_path
  size = var.vhd_size_gb * 1024 * 1024 * 1024 #Convert GB to bytes
}

resource "hyperv_virtual_machine" "windows2025" {
  name        = var.vm_name
  generation  = 2
  state       = "Running"
  notes       = "Windows Server 2025 deployed via Terraform"

  depends_on = [hyper_vhd.win2025_disk]
  
  memory_startup_bytes = var.vm_memory_mb * 1024 * 1024
  processor_count      = var.vm_cpu_count

  # Networking
  network_adaptors = [{
    name                 = "Ethernet"
    switch_name          = var.virtual_switch_name
    mac_address          = null
    dynamic_mac_address  = true
    enable_virtual_vlan  = false
    virtual_vlan_id      = 0
  }]

  # Storage
  hard_drives = [{
    controller_type     = "SCSI"
    controller_number   = 0
    controller_location = 0
    path                = hyperv_vhd.win2025_disk.path
    
  }]

  dvd_drives = [
  {
    controller_type     = "SCSI"
    controller_number   = 0
    controller_location = 1
    path                = var.windows_iso_path
  },
  {
    conrtoller_type = "SCSI"
    controller_number = 0
    controller_location = 2
    path = var.automated_iso_path # ISO containing autounattend.xml
  }
  ]

  # Secure Boot (Windows requires Microsoft UEFI cert)
  secure_boot = "MicrosoftUEFICertificateAuthority"

  # Boot order
  boot_order = ["Scsi", "Ide", "LegacyNetworkAdapter"]
}