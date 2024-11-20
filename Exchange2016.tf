resource "azurerm_public_ip" "ex2016-external" {
  name                    = "ex2016-external"
  location                = azurerm_resource_group.MyRG.location
  resource_group_name     = azurerm_resource_group.MyRG.name
  allocation_method       = "Dynamic"
  idle_timeout_in_minutes = 30
}

resource "azurerm_network_interface" "Ex2016-nic" {
  name                = "Ex2016-nic"
  location            = azurerm_resource_group.MyRG.location
  resource_group_name = azurerm_resource_group.MyRG.name

  ip_configuration {
    name                          = "Ex2016-ip"
    subnet_id                     = azurerm_subnet.vsubnet1.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.Ex2016IP
    public_ip_address_id          = azurerm_public_ip.ex2016-external.id
  }
}

resource "azurerm_virtual_machine" "Ex2016" {
  name                  = var.exname
  resource_group_name   = azurerm_resource_group.MyRG.name
  location              = azurerm_resource_group.MyRG.location
  vm_size               = "Standard_B4ms"
  network_interface_ids = [azurerm_network_interface.Ex2016-nic.id]
  
  os_profile {
    admin_username = var.admin_username
    admin_password = var.admin_password
    computer_name  = var.exname
    custom_data    = "${base64encode("${file("./exinstall.ps1")}")}"
  }

  os_profile_windows_config {
    provision_vm_agent        = true
    enable_automatic_upgrades = true
  }

  storage_os_disk {
    name              = "Ex2016-disk"
    caching           = "ReadWrite"
    disk_size_gb      = "160"
    managed_disk_type = "Standard_LRS"
    create_option     = "FromImage"
  }

  /* Auto-Login's required to configure WinRM
  additional_unattend_config {
    pass         = "oobeSystem"
    component    = "Microsoft-Windows-Shell-Setup"
    setting_name = "AutoLogon"
    content      = "<AutoLogon><Password><Value>${var.admin_password}</Value></Password><Enabled>true</Enabled><LogonCount>1</LogonCount><Username>${var.admin_username}</Username></AutoLogon>"
  }
  */

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}

resource "azurerm_dev_test_global_vm_shutdown_schedule" "Ex2016-Autoshutdown" {
  virtual_machine_id = azurerm_virtual_machine.Ex2016.id
  location           = azurerm_resource_group.MyRG.location
  enabled            = true

  daily_recurrence_time = "2000"
  timezone              = "Argentina Standard Time"

  notification_settings {
    enabled         = false
    time_in_minutes = "60"
  }
}

resource "azurerm_virtual_machine_extension" "ex2016_domjoin" {
  name                 = "ex2016_domjoin"
  virtual_machine_id   = azurerm_virtual_machine.Ex2016.id
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

resource  "azurerm_virtual_machine_extension" "ex2016_install" {
  name                 = "ex2016_install"
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"
  virtual_machine_id   = azurerm_virtual_machine.Ex2016.id
  settings             = <<SETTINGS
  {
    "commandToExecute": "powershell.exe -Command \"Copy-Item -Path c:/azuredata/customdata.bin -Destination c:/azuredata/exinstall.ps1 -Force; c:/azuredata/exinstall.ps1 -Username \"${var.active_directory_netbios_name}\\${var.admin_username}\" -Password ${var.admin_password} -NotificationRecipient ${var.notification_email}\""
  }
SETTINGS

  depends_on = [ azurerm_virtual_machine_extension.ex2016_domjoin ]
}