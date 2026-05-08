# Version History

## 0.09
- Rebuilt Windows Server 2025 ISO using `oscdimg` with `efisys_noprompt.bin` to eliminate "press any key to boot from CD" prompt for fully automated deployment.

## 0.08
- Removed KMS product key from `autounattend.xml` to resolve "Setup has failed to validate the product key" error when using the Microsoft Evaluation ISO.

## 0.07
- Resolved WinRM 401 authentication error by creating a dedicated local `hyperv-admin` account for Terraform authentication instead of using the built-in Administrator account.
- Enabled WinRM Negotiate authentication and configured HTTPS listener with a self-signed certificate on port 5986.

## 0.06
- Fixed VM boot order by explicitly setting DVD drive (0,1) as primary boot device using `Set-VMFirmware`.
- Disabled Secure Boot to resolve "signed image's hash is not allowed (DB)" error on initial boot.
- Updated `windows2025_vm.tf` to set `enable_secure_boot = "Off"`.

## 0.05
- Fixed `terraform apply` WinRM connectivity error by creating a self-signed certificate and configuring a WinRM HTTPS listener on port 5986.
- Added Windows Firewall rule to allow inbound traffic on port 5986.

## 0.04
- Resolved all `terraform validate` errors by correcting provider schema issues in `windows2025_vm.tf`:
  - Renamed `hard_drives` to `hard_disk_drives` to match `taliesins/hyperv` provider schema.
  - Removed unsupported `controller_type` argument from `dvd_drives` block.
  - Corrected `vm_firmware` boot order values from `ScsiDrive` to `HardDiskDrive` and `DvdDrive`.
  - Added `static_memory = true` to resolve required memory argument error.
  - Renamed `hyperv_virtual_machine` resource to `hyperv_machine_instance`.
  - Fixed `hyper_vhd` typo to `hyperv_vhd`.
- Populated `main.tf` with `taliesins/hyperv` provider configuration and WinRM connection settings.
- Added `autounattend_iso_path` variable to `variables.tf` and `terraform.tfvars`.
- Updated all file paths from placeholder `D:\` drive to `C:\HyperV\` directory structure.
- Updated `virtual_switch_name` in `terraform.tfvars` from `ExternalSwitch` to `External_Internet_Switch`.

## 0.03
- Added `autounattend.xml` answer file for fully unattended Windows Server 2025 installation.
  - Configured `windowsPE` pass for GPT disk partitioning, edition selection, and EULA acceptance.
  - Configured `specialize` pass for hostname and time zone settings.
  - Configured `oobeSystem` pass for administrator account, OOBE suppression, and WinRM enablement via first-logon commands.
- Updated `windows2025_vm.tf` to add `hyperv_vhd` resource and reference VHDX path from it.
- Added `vhd_size_gb` variable to `variables.tf`.
- Updated `README.md` with full file descriptions, prerequisites, and step-by-step execution guide including `autounattend.xml` documentation and ISO creation instructions.

## 0.02
- Added `PrereqCheck.ps1` script.

## 0.01
- Initial commit.