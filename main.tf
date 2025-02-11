#Create a resource group
resource "azurerm_resource_group" "Devops_project-2" {
    name = var.resource_group_name
    location = "Centralindia"
}

#Create Virtual network
resource "azurerm_virtual_network" "Vnet-1" {
    name = var.virtual_network_name
    resource_group_name = var.resource_group_name
    location = "Centralindia"
    address_space = [ "10.0.0.0/16" ]  
}

#Create a subnet
resource "azurerm_subnet" "Subnet-1" {
    name = "Subnet-1"
    resource_group_name = var.resource_group_name
    virtual_network_name = azurerm_virtual_network.Vnet-1.name
    address_prefixes = [ "10.0.1.0/24" ]
}

#Create Azure container registory.
resource "azurerm_container_registry" "ACR" {
  name = "azureimageregistory"
  resource_group_name = var.resource_group_name
  location = "Centralindia"
  sku = "Standard"
}

#Create AKS cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "Three-tier-application"
  kubernetes_version  = "1.30.6"
  location            = "Centralindia"
  resource_group_name = var.resource_group_name
  dns_prefix          = "Three-tier-application"

  default_node_pool {
    name                = "system"
    node_count          = "2"
    vm_size             = "Standard_DS2_v2"
    vnet_subnet_id = azurerm_subnet.Subnet-1.id
    type                = "VirtualMachineScaleSets"
    zones  = [1, 2, 3]
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    load_balancer_sku = "standard"
    network_plugin    = "kubenet"
  }
}

#Assign role to AKS cluster for accessing the ACR
resource "azurerm_role_assignment" "managed-identity" {
  role_definition_name = "AcrPull"
  scope = azurerm_container_registry.ACR.id
  principal_id = azurerm_kubernetes_cluster.aks.kubernetes_version
}

#Create Network Security Group 
resource "azurerm_network_security_group" "nsg" {
  name = "NSG"
  resource_group_name = var.resource_group_name
  location = "Centralindia"
  
  security_rule {

    name = "Inbound-80"
    priority = "100"
    access = "Allow"
    direction = "Inbound"
    protocol = "Tcp"
    source_address_prefix = "*" 
    destination_address_prefix = "*"
    source_port_range = "*"
    destination_port_range = "80"
  }

  security_rule {
    name = "Allow_Inbound-443"
    priority = "120"
    access = "Allow"
    direction = "Inbound"
    protocol = "Tcp"
    source_address_prefix = "*"
    destination_address_prefix = "*"
    source_port_range = "*"
    destination_port_range = "443"
  }
}

#Associate the NSG to subnet
resource "azurerm_subnet_network_security_group_association" "nsg-associ" {
  subnet_id = azurerm_subnet.Subnet-1.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}
