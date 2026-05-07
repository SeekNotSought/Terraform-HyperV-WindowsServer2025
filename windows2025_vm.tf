resource "hyperv_vhd" "win2025_disk" {
  path = var.vhd_path
  size = var.vhd_size_gb * 1024 * 1024 * 1024
}

resource "hyperv_machine_instance" "windows2025" {
  name       = var.vm_name
  generation = 2
  state      = "Running"
  notes      = "Windows Server 2025 deployed via Terraform"
  depends_on = [hyperv_vhd.win2025_disk]

  static_memory        = true
  memory_startup_bytes = var.vm_memory_mb * 1024 * 1024
  processor_count      = var.vm_cpu_count

  network_adaptors {
    name                = "Ethernet"
    switch_name         = var.virtual_switch_name
    dynamic_mac_address = true
    wait_for_ips        = false
  }

  hard_disk_drives {
    controller_type     = "Scsi"
    controller_number   = 0
    controller_location = 0
    path                = hyperv_vhd.win2025_disk.path
  }

  dvd_drives {
    controller_number   = 0
    controller_location = 1
    path                = var.windows_iso_path
  }

  dvd_drives {
    controller_number   = 0
    controller_location = 2
    path                = var.autounattend_iso_path
  }

  vm_firmware {
    enable_secure_boot   = "On"
    secure_boot_template = "MicrosoftUEFICertificateAuthority"

    boot_order {
      boot_type           = "HardDiskDrive"
      controller_number   = 0
      controller_location = 0
    }

    boot_order {
      boot_type           = "DvdDrive"
      controller_number   = 0
      controller_location = 1
    }
  }
}
