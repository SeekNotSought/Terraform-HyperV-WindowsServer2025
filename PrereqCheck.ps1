<#
.SYNOPSIS
    Validates and remediates prerequisites for using Terraform with Hyper-V.

.DESCRIPTION
    Ensures the following components are installed and configured:
    - Hyper-V role
    - Hyper-V PowerShell module
    - WinRM service and listeners
    - PowerShell Remoting
    - TrustedHosts configuration
    - Administrator privileges
    - Terraform installation check

.NOTES
    Author: SeekNotSought
    Purpose: Local Hyper-V Terraform deployments
    Version: 1.0
#>

# ---------------------------
# Helper: Require Admin
# ---------------------------
function Assert-Admin {
    if (-not ([Security.Principal.WindowsPrincipal] `
        [Security.Principal.WindowsIdentity]::GetCurrent()
        ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {

        Write-Error "This script must be run as Administrator."
        exit 1
    }
}

# ---------------------------
# Check Hyper-V Role
# ---------------------------
function Get-HyperV {
    $hv = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All

    if ($hv.State -eq "Enabled") {
        Write-Host "[OK] Hyper-V role is installed."
    }
    else {
        Write-Warning "[FIX] Hyper-V role is not installed. Installing now..."
        Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -All -NoRestart
        Write-Host "[DONE] Hyper-V role enabled. A reboot is required."
    }
}

# ---------------------------
# Check Hyper-V PowerShell Module
# ---------------------------
function Get-HyperVModule {
    if (Get-Module -ListAvailable -Name Hyper-V) {
        Write-Host "[OK] Hyper-V PowerShell module is installed."
    }
    else {
        Write-Warning "[FIX] Hyper-V PowerShell module missing. Installing..."
        Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-Management-PowerShell -All -NoRestart
        Write-Host "[DONE] Hyper-V PowerShell module installed."
    }
}

# ---------------------------
# Ensure WinRM + Remoting
# ---------------------------
function Get-WinRM {
    $service = Get-Service -Name WinRM -ErrorAction SilentlyContinue

    if ($service -and $service.Status -eq "Running") {
        Write-Host "[OK] WinRM service is running."
    }
    else {
        Write-Warning "[FIX] WinRM service not running. Enabling PSRemoting..."
        Enable-PSRemoting -Force
        Write-Host "[DONE] WinRM enabled."
    }

    # Ensure HTTP listener exists
    $listener = winrm enumerate winrm/config/listener | Select-String "Transport = HTTP"

    if ($listener) {
        Write-Host "[OK] WinRM HTTP listener exists."
    }
    else {
        Write-Warning "[FIX] Creating WinRM HTTP listener..."
        winrm quickconfig -quiet
        Write-Host "[DONE] WinRM listener created."
    }
}

# ---------------------------
# Ensure TrustedHosts
# ---------------------------
function Get-TrustedHosts {
    $current = (Get-Item -Path WSMan:\localhost\Client\TrustedHosts).Value

    if ($current -eq "*" -or $current -match "127.0.0.1") {
        Write-Host "[OK] TrustedHosts already configured."
    }
    else {
        Write-Warning "[FIX] Setting TrustedHosts to allow local WinRM..."
        Set-Item -Path WSMan:\localhost\Client\TrustedHosts -Value "*" -Force
        Write-Host "[DONE] TrustedHosts updated."
    }
}

# ---------------------------
# Check Terraform Installation
# ---------------------------
function Get-TerraformInstallStatus {
    $terraform = Get-Command terraform.exe -ErrorAction SilentlyContinue

    if ($terraform) {
        Write-Host "[OK] Terraform is installed at: $($terraform.Source)"
    }
    else {
        Write-Warning "[WARN] Terraform is NOT installed. Install from: https://developer.hashicorp.com/terraform/downloads"
    }
}

# ---------------------------
# MAIN EXECUTION
# ---------------------------
Write-Host "=== Terraform + Hyper-V Prerequisite Validator ===" -ForegroundColor Cyan

Assert-Admin
Get-HyperV
Get-HyperVModule
Get-WinRM
Get-TrustedHosts
Get-TerraformInstallStatus

Write-Host "`nAll checks complete."
