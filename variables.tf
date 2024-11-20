variable "resource_group_name" {
  default = "MyRG"
  description = "The name of the Resource Group where the Domain Controllers resources will be created"
}

variable "location" {
  default     = "eastus"
  description = "The Azure Region in which the Resource Group exists"
}

variable PublicIP {
  default = "1.1.1.1"
  description = "This is your Public IP, allowed to connect to the Network Security Group. You can run in powershell 'irm ipinfo.io' to know your current Public IP."
}

variable dcname {
  default     =  "DC"
  description = "domain controller computer name"
}

variable dcIP {
  default     = "10.0.2.10"
  description = "Domain Controller static IP Address"
}

variable exname {
  default     = "Ex2016"
  description = "Exchange Server computer name"
}

variable Ex2016IP {
  default     = "10.0.2.16"
  description = "Exchange 2016 server static IP Address"
}

variable clientname {
  default     = "Win10"
  description = "Windows 10 client computer name"
}

variable "notification_email" {
  default     = "myemailaddress@gmail.com"
  description = "This is the email account where we will send a summary email when the deployment is finished. It can be any email address."
}

# Variables for Domain Controller machine
variable "active_directory_domain" {
  default     = "azure.lab"
  description = "The name of the Active Directory domain, for example `azure.lab`"
}
variable "active_directory_netbios_name" {
  default     = "azure"
  description = "The netbios name of the Active Directory domain, for example `azure`"
}

variable "admin_username" {
  default     = "labadmin"
  description = "The username associated with the local administrator account on the virtual machine"
}

variable "admin_password" {
  default     = "LS1setup!"
  description = "The password associated with the local administrator account on the virtual machine"
}