variable "name" {
  type        = string
  description = "Name of virtual machine and prefix of other resources"
}

#   _                      ___ _                           _   
#  /_\   ____  _ _ _ ___  | _ \ |__ _ __ ___ _ __  ___ _ _| |_ 
# / _ \ |_ / || | '_/ -_) |  _/ / _` / _/ -_) '  \/ -_) ' \  _|
#/_/ \_\/__|\_,_|_| \___| |_| |_\__,_\__\___|_|_|_\___|_||_\__|
#################################################################                                                                                                                          

variable "resource_group_name" {
  type        = string
  description = "Azure Resource Group name"
}

variable "extendedLocation" {
  type        = string
  description = "Azure extendedLocation Id"
}

# __   ___     _             _   __  __         _    _          
# \ \ / (_)_ _| |_ _  _ __ _| | |  \/  |__ _ __| |_ (_)_ _  ___ 
#  \ V /| | '_|  _| || / _` | | | |\/| / _` / _| ' \| | ' \/ -_)
#   \_/ |_|_|  \__|\_,_\__,_|_| |_|  |_\__,_\__|_||_|_|_||_\___|
#################################################################                                                              

variable "vm_image" {
  type = string
  description = "Azure Stack HCI Gallery vm image name"
}

variable "subnet_id" {
  type        = string
  description = "Azure ID of the on-prem virtual network (not Azure subnet)"
}

variable "memorygb" {
  type        = number
  description = "Amount of virtual machine RAM in GBs"
  default     = 6
}

variable "processors" {
  type = number
  description = "Number of virtual machine processors"
  default = 4
}

variable "admin_username" {
  type = string
  description = "Created local admin user's username"
}

variable "admin_password" {
  type = string
  description = "Created local admin user's password"
}

variable "timezone" {
  type = string
  description = "The timezone to configure in the VM"
  default = "W. Europe Standard Time"
}

#  ___     _               _             
# | __|_ _| |_ ___ _ _  __(_)___ _ _  ___
# | _|\ \ /  _/ -_) ' \(_-< / _ \ ' \(_-<
# |___/_\_\\__\___|_||_/__/_\___/_||_/__/
#########################################

# Custom Scripts Extension
#########################
variable "cse_avd_uri" {
  type        = string
  description = "Custom script extension script location"
  default     = "https://raw.githubusercontent.com/Azure/RDS-Templates/master/ARM-wvd-templates/HCI/HciCustomScript.ps1"
}

variable "cse_avd_filename" {
  type        = string
  description = "Custom script extension script location"
  default     = "HciCustomScript.ps1"
}

variable "hostpool_name" {
  type        = string
  description = "Name of the Azure Desktop Virtualization host pool"
}

variable "host_pool_registration_token" {
  type = string
  description = "Token for registering RDS agent in host pool"
}

# ADDomainJoin Extension
#########################
variable "domain_name" {
  type        = string
  description = "FQDN of AD domain to join"
}

variable "ou_path" {
  type        = string
  description = "DN to OU in AD where to register VMs computer account"
}

variable "domain_join_user" {
  type        = string
  description = "Domain username for joining computer to domain (username only)"
}

variable "domain_join_password" {
  type        = string
  description = "Domain user password for joining computer to domain"
}
