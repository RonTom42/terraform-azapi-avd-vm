<!-- BEGIN_TF_DOCS -->
![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)

# terraform-azapi-create-avd-sesshost - Terraform module

> **Requires use of Azure Arc Resource Bridge (preview)**  
> Since Azure Arc Resource Bridge is in preview there is no Terraform provider
> for it yet. So this module uses the AzApi provider for provisioning resources.
> This might lead to some inconsistencies in resource data post deployment.
> It is recommended to run `terraform refresh` before re-applying the module.

This Terraform module will:
  - Provision a Windows VM from an existing template to an Azure Stack HCI Custom Location using Azure Arc Resource Bridge
  - Add the VM as a Session host in an Azure Virtual Desktop Pool using custom script extension
  - Enable Azure Monitor agent in the VM using Azure Monitor Extension
  - Join the VM to an on-prem domain using AD Domain join Extension

**On `terraform destroy` the Azure Virtual Desktop Pool registration will not be removed.**  
Removing the Session host registration from the Azure Virtual Desktop Pool must be done manually or by some other procedure.
Make sure that the Session host registration has been removed from the Azure Virtual Desktop Pool before redeploying resources.

---

## Example usage
```hcl
# Get Azure resource pool information
data "azurerm_resource_group" "rg_avd" {
name = var.resource_group_name
}

# Get AVD host pool information
data "azurerm_virtual_desktop_host_pool" "hostpool_avd" {
name                = var.hostpool_name
resource_group_name = data.azurerm_resource_group.rg_avd.name
}

# Create AVD host pool registration token for registering agent
resource "azurerm_virtual_desktop_host_pool_registration_info" "hostpoolreg_avd" {
hostpool_id     = data.azurerm_virtual_desktop_host_pool.hostpool_avd.id
expiration_date = timeadd(timestamp(), "1.1h")
}

# Provision and register the AVD VM(s) using the terraform-azapi-avd-vm module
module "avd_vm" {
count                        = var.number_of_vms
source                       = "git::https://github.com/RonTom42/terraform-azapi-avd-vm.git?ref=v1.0.0"
name                         = format("%s%02d", var.name, (count.index + 1))
resource_group_name          = var.resource_group_name
extendedLocation             = var.extendedLocation
subnet_id                    = var.subnet_id
domain_name                  = var.domain_name
ou_path                      = var.ou_path
domain_join_user             = var.domain_join_user
domain_join_password         = var.domain_join_password
admin_password               = var.admin_password
admin_username               = var.admin_username
vm_image                     = var.vm_image
host_pool_registration_token = azurerm_virtual_desktop_host_pool_registration_info.hostpoolreg_avd.token
hostpool_name                = var.hostpool_name
}
```

---

## Technical information

#### Providers

| Name | Version |
|------|---------|
| <a name="provider_azapi"></a> [azapi](#provider_azapi) | 1.6.0 |
| <a name="provider_azurerm"></a> [azurerm](#provider_azurerm) | 3.58.0 |

#### Requirements

No requirements.

#### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin_password"></a> [admin_password](#input_admin_password) | Created local admin user's password | `string` | n/a | yes |
| <a name="input_admin_username"></a> [admin_username](#input_admin_username) | Created local admin user's username | `string` | n/a | yes |
| <a name="input_domain_join_password"></a> [domain_join_password](#input_domain_join_password) | Domain user password for joining computer to domain | `string` | n/a | yes |
| <a name="input_domain_join_user"></a> [domain_join_user](#input_domain_join_user) | Domain username for joining computer to domain (username only) | `string` | n/a | yes |
| <a name="input_domain_name"></a> [domain_name](#input_domain_name) | FQDN of AD domain to join | `string` | n/a | yes |
| <a name="input_extendedLocation"></a> [extendedLocation](#input_extendedLocation) | Azure extendedLocation Id | `string` | n/a | yes |
| <a name="input_host_pool_registration_token"></a> [host_pool_registration_token](#input_host_pool_registration_token) | Token for registering RDS agent in host pool | `string` | n/a | yes |
| <a name="input_hostpool_name"></a> [hostpool_name](#input_hostpool_name) | Name of the Azure Desktop Virtualization host pool | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input_name) | Name of virtual machine and prefix of other resources | `string` | n/a | yes |
| <a name="input_ou_path"></a> [ou_path](#input_ou_path) | DN to OU in AD where to register VMs computer account | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource_group_name](#input_resource_group_name) | Azure Resource Group name | `string` | n/a | yes |
| <a name="input_subnet_id"></a> [subnet_id](#input_subnet_id) | Azure ID of the on-prem virtual network (not Azure subnet) | `string` | n/a | yes |
| <a name="input_vm_image"></a> [vm_image](#input_vm_image) | Azure Stack HCI Gallery vm image name | `string` | n/a | yes |
| <a name="input_cse_avd_filename"></a> [cse_avd_filename](#input_cse_avd_filename) | Custom script extension script location | `string` | `"HciCustomScript.ps1"` | no |
| <a name="input_cse_avd_uri"></a> [cse_avd_uri](#input_cse_avd_uri) | Custom script extension script location | `string` | `"https://raw.githubusercontent.com/Azure/RDS-Templates/master/ARM-wvd-templates/HCI/HciCustomScript.ps1"` | no |
| <a name="input_memorygb"></a> [memorygb](#input_memorygb) | Amount of virtual machine RAM in GBs | `number` | `6` | no |
| <a name="input_processors"></a> [processors](#input_processors) | Number of virtual machine processors | `number` | `4` | no |
| <a name="input_timezone"></a> [timezone](#input_timezone) | The timezone to configure in the VM | `string` | `"W. Europe Standard Time"` | no |

#### Outputs

| Name | Description |
|------|-------------|
| <a name="output_nic_values"></a> [nic_values](#output_nic_values) | n/a |
| <a name="output_vm_values"></a> [vm_values](#output_vm_values) | n/a |

---


<!-- END_TF_DOCS -->