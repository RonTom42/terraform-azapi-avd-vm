/**
 * # terraform-azapi-create-avd-sesshost - Terraform module
 *
 * > **Requires use of Azure Arc Resource Bridge (preview)**  
 * > Since Azure Arc Resource Bridge is in preview there is no Terraform provider
 * > for it yet. So this module uses the AzApi provider for provisioning resources.
 * > This might lead to some inconsistencies in resource data post deployment.
 * > It is recommended to run `terraform refresh` before re-applying the module.
 *
 * This Terraform module will:
 *   - Provision a Windows VM from an existing template to an Azure Stack HCI Custom Location using Azure Arc Resource Bridge
 *   - Add the VM as a Session host in an Azure Virtual Desktop Pool using custom script extension
 *   - Enable Azure Monitor agent in the VM using Azure Monitor Extension
 *   - Join the VM to an on-prem domain using AD Domain join Extension
 *
 * **On `terraform destroy` the Azure Virtual Desktop Pool registration will not be removed.**  
 * Removing the Session host registration from the Azure Virtual Desktop Pool must be done manually or by some other procedure.
 * Make sure that the Session host registration has been removed from the Azure Virtual Desktop Pool before redeploying resources.
 */

# Local variables
locals {
  cse_avd_script_uri = "https://raw.githubusercontent.com/RonTom42/avd-CustomScripts/20fe2999a57a634ff8bca6c62cb082394d38d07a/HciAvdCustomScript.ps1"
  cse_avd_script_filename = "HciAvdCustomScript.ps1"
  cse_avd_command = "powershell -ExecutionPolicy Unrestricted -File ${local.cse_avd_script_filename} -HostPoolName ${var.hostpool_name} -RegistrationInfoToken ${var.host_pool_registration_token}"
}

# Get resource pool information
data "azurerm_resource_group" "rg_avd" {
  name = var.resource_group_name
}

# Create virtual network 
# interface for virtual machine
resource "azapi_resource" "avd_vm_nic01" {
  type      = "Microsoft.AzureStackHCI/networkinterfaces@2021-09-01-preview"
  name      = format("%s-nic01", var.name)
  location  = data.azurerm_resource_group.rg_avd.location
  parent_id = data.azurerm_resource_group.rg_avd.id
  body = jsonencode({
    properties = {
      ipConfigurations = [
        {
          properties = {
            privateIPAllocationMethod = "Dynamic"
            subnet = {
              id = var.subnet_id
            }
          }
        }
      ]
    }
    extendedLocation = {
      name = var.extendedLocation
      type = "CustomLocation"
    }
  })
}

# Create virtual machine
resource "azapi_resource" "avd_vm" {
  # from https://learn.microsoft.com/en-us/azure/templates/microsoft.azurestackhci/virtualmachines?pivots=deployment-language-terraform
  type      = "Microsoft.AzureStackHCI/virtualmachines@2021-09-01-preview"
  name      = var.name
  location  = data.azurerm_resource_group.rg_avd.location
  parent_id = data.azurerm_resource_group.rg_avd.id

  identity {
    type = "SystemAssigned"
  }
  body = jsonencode({
    properties = {
      guestAgentProfile = {}
      hardwareProfile = {
        memoryGB   = var.memorygb
        processors = var.processors
        vmSize     = "Custom"
      }
      networkProfile = {
        networkInterfaces = [
          {
            id = azapi_resource.avd_vm_nic01.id
          }
        ]
      }
      osProfile = {
        adminUsername = var.admin_username
        adminPassword = var.admin_password
        computerName  = var.name
        osType        = "Windows"
        windowsConfiguration = {
          enableAutomaticUpdates = false
          provisionVMAgent       = true
          timeZone               = var.timezone
        }
      }
      resourceName = var.name
      securityProfile = {
        uefiSettings = {
          secureBootEnabled = true
        }
      }
      storageProfile = {
        dataDisks = []
        imageReference = {
          name = var.vm_image
        }
        osDisk = {}
      }
    }
    extendedLocation = {
      name = var.extendedLocation
      type = "CustomLocation"
    }
  })
}

resource "azapi_resource" "avd_vm_ext_cse" {
  lifecycle {
    ignore_changes = [body]
  }
  type      = "Microsoft.AzureStackHCI/virtualmachines/extensions@2021-09-01-preview"
  name      = format("%s-CustomScriptExtension", var.name)
  location  = data.azurerm_resource_group.rg_avd.location
  parent_id = azapi_resource.avd_vm.id
  body = jsonencode({
    properties = {
      publisher               = "Microsoft.Compute"
      type                    = "CustomScriptExtension"
      autoUpgradeMinorVersion = true
      settings = {
        fileUris = [
          local.cse_avd_script_uri
        ]
      }
      protectedSettings = {
        commandToExecute = local.cse_avd_command
      }
    }
  })
}

resource "azapi_resource" "avd_vm_ext_azmonitor" {
  lifecycle {
    ignore_changes = [body]
  }
  type      = "Microsoft.AzureStackHCI/virtualmachines/extensions@2021-09-01-preview"
  name      = format("%s-azmonitor-avd", var.name)
  location  = data.azurerm_resource_group.rg_avd.location
  parent_id = azapi_resource.avd_vm.id
  body = jsonencode({
    properties = {
      publisher               = "Microsoft.Azure.Monitor"
      type                    = "AzureMonitorWindowsAgent"
      typeHandlerVersion      = "1.5"
      autoUpgradeMinorVersion = true
    }
  })
}

# Add JoinDomain Extention to VM
# Runs last (with use of depends_on) and reboots
resource "azapi_resource" "avd_vm_ext_joindomain" {
  depends_on = [ azapi_resource.avd_vm_ext_cse, azapi_resource.avd_vm_ext_azmonitor ]
  lifecycle {
    ignore_changes = [body]
  }
  type      = "Microsoft.AzureStackHCI/virtualmachines/extensions@2021-09-01-preview"
  name      = format("%s-joindomain-avd", var.name)
  location  = data.azurerm_resource_group.rg_avd.location
  parent_id = azapi_resource.avd_vm.id
  body = jsonencode({
    properties = {
      publisher               = "Microsoft.Compute"
      type                    = "JsonADDomainExtension"
      typeHandlerVersion      = "1.3"
      autoUpgradeMinorVersion = true
      settings = {
        name    = var.domain_name # domain name
        oUPath  = var.ou_path
        user    = format("%s\\%s", var.domain_name, var.domain_join_user) # Domain user <user@domain-fqdn>
        restart = true
        options = "3"

      }
      protectedSettings = {
        password = var.domain_join_password
      }
    }
  })
}

output "vm_values" {
  value = azapi_resource.avd_vm
}

output "nic_values" {
  value = azapi_resource.avd_vm_nic01
}

