provider "azurerm" {
  # The "feature" block is required for AzureRM provider 2.x. 
  # If you're using version 1.x, the "features" block is not allowed.
  version = "~>2.0"
  features {}
}

# Create a resource group if it doesn't exist
resource "azurerm_resource_group" "var.resource_group_name" {
  name     = "var.resource_group_name"
  location = "var.location"

  tags = {
    environment = "Terraform Demo"
  }
}

resource "azurerm_virtual_network" "vnetwork" {
  name                = "terraDemo-network"
  address_space       = ["10.0.0.0/16"]
  dns_servers         = [ var.dcIP ]
  location            = azurerm_resource_group.MyRG.location
  resource_group_name = azurerm_resource_group.MyRG.name
}

resource "azurerm_subnet" "vsubnet1" {
  name                 = "subnet1"
  resource_group_name  = azurerm_resource_group.MyRG.name
  virtual_network_name = azurerm_virtual_network.vnetwork.name
  address_prefixes     = ["10.0.2.0/24"]
}


## Create Virtual Network Security Group
resource "azurerm_network_security_group" "MyNSG" {
  name                = "MyNSG"
  location            = azurerm_resource_group.MyRG.location
  resource_group_name = azurerm_resource_group.MyRG.name
}

## Adding inbound network Rule
resource "azurerm_network_security_rule" "InboundSecurityRule_port3389" {
  name                        = "Inbound3389"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = var.PublicIP
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.MyRG.name
  network_security_group_name = azurerm_network_security_group.MyNSG.name
}

## Associating NSG to the management Subnet
resource "azurerm_subnet_network_security_group_association" "MyNSGAssociation" {
  subnet_id                 = azurerm_subnet.vsubnet1.id
  network_security_group_id = azurerm_network_security_group.MyNSG.id
}