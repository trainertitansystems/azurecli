#Create Windows Virtual machines
# /Users/shaz/Downloads/terralearn/azure

provider "azurerm" {
  features {}

  subscription_id = "8b107c0d-c1d5-4c8f-a280-8bde452105f1"
  client_id       = "c26c32e7-b59e-4767-ad8b-91299161d15f"
  client_secret   = "u~S8Q~oLfqkSjPc2IDWtd3_UqyZ7j2WqRSsk5drI"
  tenant_id       = "4c8c783d-75d4-4118-8a1e-addec91e4a9a"
}


# Data block to reference the existing Resource Group
data "azurerm_resource_group" "existing_rg" {
  name = "titansystems"
}

# Data block to reference the existing Virtual Network
data "azurerm_virtual_network" "existing_vnet" {
  name                = "test-vnet"
  resource_group_name = data.azurerm_resource_group.existing_rg.name
}

# Data block to reference the existing Subnet
data "azurerm_subnet" "existing_subnet" {
  name                 = "default"
  virtual_network_name = data.azurerm_virtual_network.existing_vnet.name
  resource_group_name  = data.azurerm_resource_group.existing_rg.name
}

# Create a Public IP Address
resource "azurerm_public_ip" "vm_public_ip" {
  name                = "vm-public-ip"
  location            = data.azurerm_resource_group.existing_rg.location
  resource_group_name = data.azurerm_resource_group.existing_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Create a Network Security Group
resource "azurerm_network_security_group" "vm_nsg" {
  name                = "vm-nsg"
  location            = data.azurerm_resource_group.existing_rg.location
  resource_group_name = data.azurerm_resource_group.existing_rg.name

  security_rule {
    name                       = "RDP"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create a Network Interface and associate with Public IP and NSG
resource "azurerm_network_interface" "vm_nic" {
  name                = "vm-nic"
  location            = data.azurerm_resource_group.existing_rg.location
  resource_group_name = data.azurerm_resource_group.existing_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.existing_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm_public_ip.id
  }

  network_security_group_id = azurerm_network_security_group.vm_nsg.id
}

# Create the Windows Virtual Machine
resource "azurerm_windows_virtual_machine" "example_vm" {
  name                = "example-vm"
  location            = data.azurerm_resource_group.existing_rg.location
  resource_group_name = data.azurerm_resource_group.existing_rg.name
  size                = "Standard_DS1_v2"
  admin_username      = "adminuser"
  admin_password      = "P@ssw0rd1234!"  # Ensure this meets Azure's password complexity requirements
  network_interface_ids = [azurerm_network_interface.vm_nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }
}

# Output the VM's Public IP Address
output "vm_public_ip_address" {
  value = azurerm_public_ip.vm_public_ip.ip_address
}
