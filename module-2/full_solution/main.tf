provider "azurerm" {
  features {}
}

provider "tls" {}

locals {
  rootname         = "bctf-${var.yourname}-${var.location}"
  trimmed_rootname = "bctf${var.yourname}${var.location}"
  tags = {
    "costCenter" = "BrightCubesInternal"
    "owner"      = var.yourname
    "region"     = var.location
  }
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "bctf-rg" {
  name     = "${local.rootname}-rg"
  location = var.location
  tags     = local.tags
}

resource "azurerm_storage_account" "bctf-sa" {
  name                = "${local.trimmed_rootname}sa"
  resource_group_name = azurerm_resource_group.bctf-rg.name
  location            = var.location
  tags                = local.tags

  account_tier             = "Standard"
  account_replication_type = "LRS"
}

data "azurerm_virtual_network" "bctf-vnet" {
  name                = "bctf-workshop-vnet"
  resource_group_name = "bctf-workshop-rg"
}

resource "azurerm_subnet" "bctf-subnet" {
  name                 = "${local.rootname}-subnet"
  resource_group_name  = data.azurerm_virtual_network.bctf-vnet.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.bctf-vnet.name
  address_prefixes     = ["10.0.90.0/24"]
  service_endpoints    = ["Microsoft.Storage", "Microsoft.KeyVault"]
}

resource "azurerm_public_ip" "bctf-pip" {
  name                = "${local.rootname}-pip"
  location            = var.location
  resource_group_name = azurerm_resource_group.bctf-rg.name
  allocation_method   = "Dynamic"
  tags                = local.tags
}

resource "azurerm_network_interface" "bctf-nic" {
  name                = "${local.rootname}-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.bctf-rg.name
  tags                = local.tags

  ip_configuration {
    name                          = "${local.rootname}-nic-cfg"
    subnet_id                     = azurerm_subnet.bctf-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.bctf-pip.id
  }
}

resource "azurerm_network_security_group" "bctf-nsg" {
  name                = "${local.rootname}-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.bctf-rg.name
  tags                = local.tags
}

resource "azurerm_subnet_network_security_group_association" "bctf-nsg_to_subnet" {
  subnet_id                 = azurerm_subnet.bctf-subnet.id
  network_security_group_id = azurerm_network_security_group.bctf-nsg.id
}

resource "azurerm_network_security_rule" "ssh-access" {
  name                        = "Allow-SSH"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = var.my_ip_address # Your own IP address
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.bctf-rg.name
  network_security_group_name = azurerm_network_security_group.bctf-nsg.name
}

resource "azurerm_key_vault" "bctf-kv" {
  name                = "${local.trimmed_rootname}-kv"
  location            = var.location
  resource_group_name = azurerm_resource_group.bctf-rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
  tags                = local.tags

  enable_rbac_authorization  = false
  soft_delete_retention_days = 10

  network_acls {
    default_action             = "Deny"
    bypass                     = "AzureServices"
    virtual_network_subnet_ids = [azurerm_subnet.bctf-subnet.id]
    ip_rules                   = ["${var.my_ip_address}"] # Your own IP address
  }
}

resource "azurerm_key_vault_access_policy" "bctf-kv-current-ap" {
  key_vault_id       = azurerm_key_vault.bctf-kv.id
  tenant_id          = data.azurerm_client_config.current.tenant_id
  object_id          = data.azurerm_client_config.current.object_id
  secret_permissions = ["Get", "Set", "List", ]
}

resource "azurerm_key_vault_access_policy" "bctf-kv-vm-ap" {
  key_vault_id       = azurerm_key_vault.bctf-kv.id
  tenant_id          = data.azurerm_client_config.current.tenant_id
  object_id          = azurerm_linux_virtual_machine.bctf-vm.identity[0].principal_id
  secret_permissions = ["Get", "Set", "List", ]
}

resource "tls_private_key" "bctf-ssh-key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_key_vault_secret" "bctf-private-key" {
  name            = "private-key-openssh"
  value           = tls_private_key.bctf-ssh-key.private_key_openssh
  key_vault_id    = azurerm_key_vault.bctf-kv.id
  expiration_date = "2022-12-31T00:00:00Z"
  content_type    = "openssh private key"

  depends_on = [
    azurerm_key_vault_access_policy.bctf-kv-current-ap
  ]
}

resource "azurerm_key_vault_secret" "bctf-public-key" {
  name            = "public-key-openssh"
  value           = tls_private_key.bctf-ssh-key.public_key_openssh
  key_vault_id    = azurerm_key_vault.bctf-kv.id
  expiration_date = "2022-12-31T00:00:00Z"
  content_type    = "openssh public key"

  depends_on = [
    azurerm_key_vault_access_policy.bctf-kv-current-ap
  ]
}

resource "azurerm_linux_virtual_machine" "bctf-vm" {
  name                  = "${local.rootname}-vm"
  location              = var.location
  resource_group_name   = azurerm_resource_group.bctf-rg.name
  size                  = var.vm_size
  network_interface_ids = [azurerm_network_interface.bctf-nic.id]
  admin_username        = var.yourname
  computer_name         = local.trimmed_rootname
  tags                  = local.tags

  admin_ssh_key {
    username   = var.yourname
    public_key = azurerm_key_vault_secret.bctf-public-key.value
  }
  disable_password_authentication = true

  # admin_password = "ThisWasSuchACoolWorkshop!1!"
  # disable_password_authentication = false

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.os_disk_sku
    disk_size_gb         = var.os_disk_size
  }

  identity {
    type = "SystemAssigned"
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.bctf-sa.primary_blob_endpoint
  }
}