# Terraform-HyperV-WindowsServer2025

Deploys a Windows Server 2025 virtual machine on Hyper-V using Terraform.

---

## ⚠️ Notes

- Passwords in `terraform.tfvars` are placeholders. **Do not commit real credentials to source control.** Use environment variables for secrets (see [Execution](#execution) below).
- An `autounattend.xml` is required for fully unattended OS installation. Without it, Windows Setup will pause for manual input after the VM boots.

---

## File Descriptions

### `PrereqCheck.ps1`
A PowerShell script that validates and remediates all prerequisites needed to use Terraform with Hyper-V on the local machine. Run this **before** your first `terraform init`. It checks and auto-fixes the following:

- Hyper-V Windows role is enabled
- Hyper-V PowerShell management module is installed
- WinRM service is running with an HTTP listener configured
- PowerShell Remoting is enabled
- `TrustedHosts` is configured to allow local WinRM connections
- Terraform executable is installed and on the system PATH

### `main.tf`
Defines the Terraform provider configuration. This file tells Terraform to use the `taliesins/hyperv` provider and configures how it connects to the local Hyper-V host via WinRM (host, port, credentials, and TLS settings).

### `variables.tf`
Declares all input variables used across the project. No values are set here — it only defines variable names, types, descriptions, and optional defaults. Variables include:

- `vm_name` — Name of the virtual machine
- `vm_memory_mb` — RAM allocated to the VM in MB (default: 8192)
- `vm_cpu_count` — Number of virtual processors (default: 4)
- `vhd_size_gb` — Size of the virtual hard disk in GB (default: 80)
- `windows_iso_path` — Full path to the Windows Server 2025 ISO
- `vhd_path` — Full path where the VHDX disk file will be created
- `virtual_switch_name` — Name of the Hyper-V virtual switch to attach to
- `admin_username` — Local administrator username
- `admin_password` — Local administrator password (marked sensitive)

### `terraform.tfvars`
Supplies the actual values for the variables declared in `variables.tf`. This is the **primary file you edit** to configure your deployment (VM name, paths, switch name, etc.).

> **Security note:** Remove `admin_password` from this file and pass it via an environment variable instead (see [Execution](#execution)).

### `windows2025_vm.tf`
Contains the two core Terraform resources that build the VM:

1. **`hyperv_vhd`** — Creates the VHDX virtual hard disk at the specified path and size before the VM is provisioned.
2. **`hyperv_virtual_machine`** — Defines the virtual machine itself, including generation (Gen 2), memory, vCPU count, network adapter, storage (referencing the VHDX created above), DVD drive (mounted with the Windows ISO), and Secure Boot settings. The VM depends on the VHDX resource so Terraform always creates the disk first.

---

## Prerequisites

1. Windows 10/11 or Windows Server host with virtualization enabled in BIOS/UEFI
2. [Terraform](https://developer.hashicorp.com/terraform/downloads) installed and on your PATH
3. A Windows Server 2025 ISO downloaded and accessible on the Hyper-V host
4. An existing Hyper-V virtual switch (External, Internal, or Private)

---

## Execution

### Step 1 — Validate prerequisites

Open PowerShell **as Administrator** and run:

```powershell
.\PrereqCheck.ps1
```

Resolve any warnings before continuing. A reboot may be required if Hyper-V was just enabled.

### Step 2 — Configure your deployment

Edit `terraform.tfvars` with your environment-specific values:

```hcl
vm_name             = "win2025-lab"
vm_memory_mb        = 8192
vm_cpu_count        = 4
vhd_size_gb         = 80

windows_iso_path    = "D:\\ISOs\\WindowsServer2025.iso"
vhd_path            = "D:\\Hyper-V\\Virtual Hard Disks\\win2025.vhdx"
virtual_switch_name = "ExternalSwitch"

admin_username      = "Administrator"
# Do not set admin_password here — use the environment variable below
```

### Step 3 — Set your password via environment variable

Instead of hardcoding the password in `terraform.tfvars`, set it as an environment variable in your PowerShell session:

```powershell
$env:TF_VAR_admin_password = "YourSecurePasswordHere"
```

Terraform automatically picks up any environment variable prefixed with `TF_VAR_`.

### Step 4 — Initialize Terraform

Download the required provider:

```powershell
terraform init
```

### Step 5 — Preview the deployment

Review what Terraform will create before applying:

```powershell
terraform plan
```

### Step 6 — Deploy

Apply the configuration to create the VHDX and virtual machine:

```powershell
terraform apply
```

Type `yes` when prompted to confirm.

### Step 7 — Destroy (optional)

To remove the VM and all associated resources:

```powershell
terraform destroy
```

---

## Project Structure

```
.
├── PrereqCheck.ps1      # Prerequisite validation script
├── main.tf              # Terraform provider configuration
├── variables.tf         # Variable declarations
├── terraform.tfvars     # Variable values (your config)
├── windows2025_vm.tf    # VHDX and VM resource definitions
├── README.md            # This file
└── changelog.md         # Version history
```