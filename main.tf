terraform {
  required_version = ">= 1.5.0"

  required_providers {
    hyperv = {
      source  = "taliesins/hyperv"
      version = "~> 0.5"
    }
  }
}

provider "hyperv" {
  user = var.admin_username
  password = var.admin_password
  host = "127.0.0.1"
  port = 5986
  https = true
  insecure = true
  use_ntlm = true
}