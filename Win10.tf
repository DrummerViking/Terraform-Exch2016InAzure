resource "azurerm_network_interface" "Win10-nic" {
  name                = "Win10-nic"
  location            = azurerm_resource_group.MyRG.location
  resource_group_name = azurerm_resource_group.MyRG.name

  ip_configuration {
    name                          = "Win10-ip"
    subnet_id                     = azurerm_subnet.vsubnet1.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "Win10" {
  name                  = var.clientname
  resource_group_name   = azurerm_resource_group.MyRG.name
  location              = azurerm_resource_group.MyRG.location
  size                  = "Standard_B2ms"
  admin_username        = var.admin_username
  admin_password        = var.admin_password
  network_interface_ids = [azurerm_network_interface.Win10-nic.id]
  provision_vm_agent    = true
  enable_automatic_updates = true
  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true
  
  os_disk {
    caching           = "ReadWrite"
    disk_size_gb      = "128"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-10"
    sku       = "20h2-pro"
    version   = "latest"
  }
}

resource "azurerm_dev_test_global_vm_shutdown_schedule" "Win10-Autoshutdown" {
  virtual_machine_id = azurerm_windows_virtual_machine.Win10.id
  location           = azurerm_resource_group.MyRG.location
  enabled            = true

  daily_recurrence_time = "2000"
  timezone              = "Argentina Standard Time"

  notification_settings {
    enabled         = false
    time_in_minutes = "60"
  }
}

resource "azurerm_virtual_machine_extension" "Win10-wait-for-domain-to-provision" {
  name                 = "TestConnectionDomain"
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"
  virtual_machine_id   = azurerm_windows_virtual_machine.Win10.id
  settings             = <<SETTINGS
  {
    "commandToExecute": "powershell.exe -Command \"while (!(Test-Connection -ComputerName ${var.active_directory_domain} -Count 1 -Quiet) -and ($retryCount++ -le 360)) { Start-Sleep 10 } \""
  }
SETTINGS
}

resource "azurerm_virtual_machine_extension" "win10_domjoin" {
  name                 = "Win10_domjoin"
  virtual_machine_id   = azurerm_windows_virtual_machine.Win10.id
  publisher            = "Microsoft.Compute"
  type                 = "JsonADDomainExtension"
  type_handler_version = "1.3"

  settings = <<SETTINGS
  {
    "Name" : "${var.active_directory_domain}",
    "OUPath" : "",
    "User" : "${var.active_directory_netbios_name}\\${var.admin_username}",
    "Restart" : "true",
    "Options" : "3"
  }
  SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
{
  "Password" : "${var.admin_password}"
}
  PROTECTED_SETTINGS

  depends_on = [ azurerm_virtual_machine_extension.Win10-wait-for-domain-to-provision ]
}
