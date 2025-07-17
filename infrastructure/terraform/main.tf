# Configure the Azure Provider
terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Data source for existing resource group
data "azurerm_resource_group" "existing" {
  name = var.resource_group_name
}

# Create Virtual Network for the AKS cluster
resource "azurerm_virtual_network" "aks_vnet" {
  name                = "${var.aks_cluster_name}-vnet"
  location            = data.azurerm_resource_group.existing.location
  resource_group_name = data.azurerm_resource_group.existing.name
  address_space       = [var.vnet_address_space]
  tags                = var.tags
}

# Create a Subnet within the VNet for the AKS nodes
resource "azurerm_subnet" "aks_subnet" {
  name                 = "aks-subnet"
  resource_group_name  = data.azurerm_resource_group.existing.name
  virtual_network_name = azurerm_virtual_network.aks_vnet.name
  address_prefixes     = [var.subnet_address_prefix]
}

# Create a Network Security Group to control traffic to the subnet
resource "azurerm_network_security_group" "aks_nsg" {
  name                = "${var.aks_cluster_name}-nsg"
  location            = data.azurerm_resource_group.existing.location
  resource_group_name = data.azurerm_resource_group.existing.name
  tags                = var.tags
}

# Rule to allow HTTP traffic for the Ingress Controller
resource "azurerm_network_security_rule" "allow_http" {
  name                        = "Allow_HTTP_Ingress"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "Internet"
  destination_address_prefix  = "*"
  resource_group_name         = data.azurerm_resource_group.existing.name
  network_security_group_name = azurerm_network_security_group.aks_nsg.name
}

# Rule to allow HTTPS traffic for the Ingress Controller
resource "azurerm_network_security_rule" "allow_https" {
  name                        = "Allow_HTTPS_Ingress"
  priority                    = 201
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "Internet"
  destination_address_prefix  = "*"
  resource_group_name         = data.azurerm_resource_group.existing.name
  network_security_group_name = azurerm_network_security_group.aks_nsg.name
}

# Associate the NSG with the AKS Subnet
resource "azurerm_subnet_network_security_group_association" "aks_nsg_assoc" {
  subnet_id                 = azurerm_subnet.aks_subnet.id
  network_security_group_id = azurerm_network_security_group.aks_nsg.id
}

# Define the Azure Kubernetes Service (AKS) cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_cluster_name
  location            = data.azurerm_resource_group.existing.location
  resource_group_name = data.azurerm_resource_group.existing.name
  dns_prefix          = var.aks_dns_prefix
  tags                = var.tags

  default_node_pool {
    name       = "default"
    node_count = var.aks_node_count
    vm_size    = var.aks_vm_size
    vnet_subnet_id = azurerm_subnet.aks_subnet.id

    upgrade_settings {
      drain_timeout_in_minutes      = 0
      max_surge                     = "10%"
      node_soak_duration_in_minutes = 0
    }
  }

  identity {
    type = "SystemAssigned"
  }

  # Network Profile
  network_profile {
    network_plugin     = "azure"
    network_policy     = "azure"
    load_balancer_sku  = "standard"
    service_cidr       = "10.0.0.0/16"
    dns_service_ip     = "10.0.0.10"
  }
} 