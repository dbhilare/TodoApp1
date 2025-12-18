# -----------------------------
# Resource Group
# -----------------------------
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# -----------------------------
# Virtual Network
# -----------------------------
resource "azurerm_virtual_network" "vnet" {
  name                = "react-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "react-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# -----------------------------
# Public IP
# -----------------------------
resource "azurerm_public_ip" "pip" {
  name                = "react-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# -----------------------------
# Network Security Group
# -----------------------------
resource "azurerm_network_security_group" "nsg" {
  name                = "react-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# -----------------------------
# Network Interface
# -----------------------------
resource "azurerm_network_interface" "nic" {
  name                = "react-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}


resource "azurerm_network_interface_security_group_association" "nsg_assoc" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}


# -----------------------------
# Linux Virtual Machine
# -----------------------------
resource "azurerm_linux_virtual_machine" "vm" {
  name                = "vm1"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B2s"

  admin_username = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    #public_key = var.ssh_public_key
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC04SLwMrA53q8IRBU85NosNDqcf0U4CNzuYeqxld8A3LtB6tL/KLpZdXerMJ118B9gx5FvjBuruiLc3/f+JZ8o8UHQ6hFkhvFhwjPvJZ0qf2tNY4ewzZVgpALxNT4VoJso2pr89rHJ1cWYMhwD/hyg+w5BVgmLwqAyD4ZB51Q9zfInLQAOZbpF5lL5T4G/ApE+f4xXwulE0xfZrVXR7zGeT+yU8HbE2zs4NzRkVGugU8X+hmLChKho1YvhFwsE6Djd789W45ypRyjuCGdChlLZl6F2knDShEP8XgSuhPFohbIjYpOGaUgFnaUhoKVjVbstj4n/5kwVlU1tFSRMV98g15aJYtKiZ6BCGkoygm27yIQWr6aHvTjN8qmxHrV25TP0dXO86P3bwkJ5fvMwxDmlOSQLqxdFlf5v/RHsSCXF3ovpyN/zo77izTcVeVQ0nTqTrjI0qQJjktKfAjKeqPA/Y7v+ZL9N2/H2mxSW2U+dax6caLvYV4PQXxltU43SHI0knxUhQ04cWRSIQhAgRaVkKeW0xVHBQphqqKjVxjUEFg4H1X+rU9jQAEs3Zr6EiwgBm6yy2gr/Msx7hbbhsfrSIO7teamB8apgqk0IklVtzbVeBdjWXgLR4Xu4iLsSaa6YpqVFRoACWXpP7+OKUCdE+RUOr9dv14D/M+9NVnhy9w=="
  }

  os_disk {
    name                 = "vm1-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }
}

#Assign Storage Blob Data Reader role (Terraform)
resource "azurerm_role_assignment" "vm_storage_reader" {
  scope                = azurerm_storage_account.tfstate.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_linux_virtual_machine.vm.identity[0].principal_id
}



