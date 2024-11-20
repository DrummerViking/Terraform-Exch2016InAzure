resource "azurerm_public_ip" "dc-external" {
  name                         = "dc-external"
  location            = azurerm_resource_group.MyRG.location
  resource_group_name = azurerm_resource_group.MyRG.name
  allocation_method = "Dynamic"
  idle_timeout_in_minutes      = 30
}

resource "azurerm_network_interface" "DC-nic" {
  name                = "DC-nic"
  location            = azurerm_resource_group.MyRG.location
  resource_group_name = azurerm_resource_group.MyRG.name

  ip_configuration {
    name                          = "DC-ip"
    subnet_id                     = azurerm_subnet.vsubnet1.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.dcIP
    public_ip_address_id          = azurerm_public_ip.dc-external.id
  }
}

resource "azurerm_windows_virtual_machine" "DC" {
  name                  = var.dcname
  resource_group_name   = azurerm_resource_group.MyRG.name
  location              = azurerm_resource_group.MyRG.location
  size                  = "Standard_B2s"
  admin_username        = var.admin_username
  admin_password        = var.admin_password
  network_interface_ids = [azurerm_network_interface.DC-nic.id]
  provision_vm_agent    = true
  enable_automatic_updates = true

  os_disk {
    caching              = "ReadWrite"
    disk_size_gb         = "128"
    storage_account_type = "Standard_LRS"
  }

  identity {
    type = "SystemAssigned"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}

resource "azurerm_dev_test_global_vm_shutdown_schedule" "DC-Autoshutdown" {
  virtual_machine_id = azurerm_windows_virtual_machine.DC.id
  location           = azurerm_resource_group.MyRG.location
  enabled            = true

  daily_recurrence_time = "2010"
  timezone              = "Argentina Standard Time"

  notification_settings {
    enabled         = false
    time_in_minutes = "60"
  }
}