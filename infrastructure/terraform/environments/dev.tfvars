# Development Environment Configuration - Simple and Affordable
resource_group_name = "rg-klass-online-dev"

# AKS Cluster Configuration
aks_cluster_name = "klass-online-dev-aks"
aks_dns_prefix   = "klass-online-dev"
aks_node_count   = 1
aks_vm_size      = "Standard_B2s"  # Cheapest option for basic workloads

# Networking
vnet_address_space    = "10.0.0.0/16"
subnet_address_prefix = "10.0.1.0/24"

# Tags
tags = {
  Environment = "dev"
  Project     = "klass-online"
  ManagedBy   = "terraform"
} 