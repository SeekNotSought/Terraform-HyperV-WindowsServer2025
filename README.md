# Terraform-HyperV-WindowsServer2025

Deploys a Windows Server 2025 virtual machine on Hyper-V using Terraform.

---

## ⚠️ Notes

- Passwords in `terraform.tfvars` are placeholders. **Do not commit real credentials to source control.** Use environment variables for secrets (see [Execution](#execution) below).
- `autounattend.xml` contains `PLACEHOLDER_PASSWORD` and `PLACEHOLDER_USERNAME` values that **must be replaced** before use. See the [autounattend.xml](#autounattendxml) file description and [Step 2a](#step-2a--prepare-autounattendxml) below.
- Do not commit `autounattend.xml` with real passwords to source control.

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
2. **`hyperv_virtual_machine`** — Defines the virtual machine itself, including generation (Gen 2), memory, vCPU count, network adapter, storage (referencing the VHDX created above), DVD drives (Windows ISO + autounattend ISO), and Secure Boot settings. The VM depends on the VHDX resource so Terraform always creates the disk first.

### `autounattend.xml`
An XML answer file consumed by Windows Setup to perform a fully automated, zero-touch OS installation. Windows Setup automatically detects this file at the root of any attached drive — no path configuration is required. It drives three setup passes:

**`windowsPE` pass** — runs inside the Windows PE environment before installation begins:
- Sets the install UI language, system locale, and input locale to `en-US`
- Accepts the EULA automatically
- Applies a KMS product key to select the Windows Server 2025 Standard (Desktop Experience) edition without prompting
- Partitions disk 0 using GPT (required for Gen 2 / UEFI): EFI System Partition (100 MB), Microsoft Reserved (16 MB), and a Windows OS partition using the remaining disk space
- Installs Windows to the OS partition with no UI

**`specialize` pass** — runs after the first reboot:
- Sets the computer hostname (matches `vm_name` in `terraform.tfvars`)
- Sets the time zone to `Eastern Standard Time`
- Disables Server Manager from auto-launching at logon

**`oobeSystem` pass** — runs during the Out-of-Box Experience phase:
- Suppresses all OOBE interactive screens (EULA, network, privacy, account setup)
- Sets the built-in Administrator password
- Optionally creates a named local administrator account
- Configures a one-time auto-logon after setup completes
- Runs first-logon commands to enable and configure WinRM (ports 5985 and 5986) so the VM is immediately accessible for remote management via Terraform, Ansible, or PowerShell

> **Before use:** Replace all three occurrences of `PLACEHOLDER_PASSWORD` with your actual administrator password, and `PLACEHOLDER_USERNAME` with your desired local account name. See [Step 2a](#step-2a--prepare-autounattendxml) below.

#### Product Key Reference

The file ships with the Standard (Desktop Experience) generic KMS key. Swap `<Key>` in the `windowsPE` pass if you need a different edition:

| Edition | Key |
|---|---|
| Standard — Desktop Experience | `VDYBN-27WPP-V4HQT-9VMD4-VMK7H` |
| Standard — Core | `TVRH6-WHNXV-R9WG3-9XRFY-MY832` |
| Datacenter — Desktop Experience | `D764K-2NDRG-47T6Q-P8T8W-YP6DF` |
| Datacenter — Core | `CB7KF-BWN84-R7R2Y-793K2-8XDDG` |

---

## Prerequisites

1. Windows 10/11 or Windows Server host with virtualization enabled in BIOS/UEFI
2. [Terraform](https://developer.hashicorp.com/terraform/downloads) installed and on your PATH
3. A Windows Server 2025 ISO downloaded and accessible on the Hyper-V host
4. An existing Hyper-V virtual switch (External, Internal, or Private)
5. [oscdimg](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/oscdimg-command-line-options) or [mkisofs](https://sourceforge.net/projects/cdrtfe/) to package `autounattend.xml` into a bootable ISO

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
vm_name              = "win2025-lab"
vm_memory_mb         = 8192
vm_cpu_count         = 4
vhd_size_gb          = 80

windows_iso_path     = "D:\\ISOs\\WindowsServer2025.iso"
autounattend_iso_path = "D:\\ISOs\\autounattend.iso"
vhd_path             = "D:\\Hyper-V\\Virtual Hard Disks\\win2025.vhdx"
virtual_switch_name  = "ExternalSwitch"

admin_username       = "Administrator"
# Do not set admin_password here — use the environment variable below
```

### Step 2a — Prepare `autounattend.xml`

Open `autounattend.xml` and replace all placeholder values:

| Placeholder | Replace with |
|---|---|
| `PLACEHOLDER_PASSWORD` | Your administrator password (appears 3 times) |
| `PLACEHOLDER_USERNAME` | Your desired local account name |

Then package the file into a small ISO so Hyper-V can attach it as a second DVD drive. Windows Setup automatically detects `autounattend.xml` at the root of any attached drive.

**Using oscdimg (Windows ADK):**
```powershell
# Create a staging folder with autounattend.xml at its root
New-Item -ItemType Directory -Path "C:\autounattend-staging"
Copy-Item autounattend.xml "C:\autounattend-staging\"

# Build the ISO
oscdimg -u2 -udfver102 "C:\autounattend-staging" "D:\ISOs\autounattend.iso"
```

**Using mkisofs (Linux / WSL):**
```bash
mkisofs -o /mnt/d/ISOs/autounattend.iso autounattend.xml
```

Place the resulting ISO at the path you set for `autounattend_iso_path` in `terraform.tfvars`.

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
├── autounattend.xml     # Unattended Windows Setup answer file
├── README.md            # This file
└── changelog.md         # Version history
```