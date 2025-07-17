# AKS Cluster Outputs
output "aks_cluster_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.name
}

output "aks_cluster_id" {
  description = "ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.id
}

output "aks_host" {
  description = "AKS cluster host"
  value       = azurerm_kubernetes_cluster.aks.kube_config[0].host
  sensitive   = true
}

output "aks_client_certificate" {
  description = "AKS cluster client certificate"
  value       = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate)
  sensitive   = true
}

output "aks_client_key" {
  description = "AKS cluster client key"
  value       = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_key)
  sensitive   = true
}

output "aks_cluster_ca_certificate" {
  description = "AKS cluster CA certificate"
  value       = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate)
  sensitive   = true
}

output "aks_kube_config_raw" {
  description = "Raw kube config for the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive   = true
}

# Networking Outputs
output "vnet_id" {
  description = "ID of the Virtual Network"
  value       = azurerm_virtual_network.aks_vnet.id
}

output "vnet_name" {
  description = "Name of the Virtual Network"
  value       = azurerm_virtual_network.aks_vnet.name
}

output "aks_subnet_id" {
  description = "ID of the AKS subnet"
  value       = azurerm_subnet.aks_subnet.id
}

output "aks_subnet_name" {
  description = "Name of the AKS subnet"
  value       = azurerm_subnet.aks_subnet.name
}

output "nsg_id" {
  description = "ID of the Network Security Group"
  value       = azurerm_network_security_group.aks_nsg.id
}

output "nsg_name" {
  description = "Name of the Network Security Group"
  value       = azurerm_network_security_group.aks_nsg.name
}

# Resource Group Outputs
output "resource_group_name" {
  description = "Name of the resource group"
  value       = data.azurerm_resource_group.existing.name
}

output "resource_group_location" {
  description = "Location of the resource group"
  value       = data.azurerm_resource_group.existing.location
} 