# Production Environment Configuration - Simple and Affordable
resource_group_name = "rg-klass-online-prod"

# AKS Cluster Configuration
aks_cluster_name = "klass-online-prod-aks"
aks_dns_prefix   = "klass-online-prod"
aks_node_count   = 2  # Slightly more for production reliability
aks_vm_size      = "Standard_B2s"  # Still affordable but can handle more load

# Networking
vnet_address_space    = "10.0.0.0/16"
subnet_address_prefix = "10.0.1.0/24"

# Tags
tags = {
  Environment = "production"
  Project     = "klass-online"
  ManagedBy   = "terraform"
} 