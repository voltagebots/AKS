resource "azurerm_resource_group" "k8s" {
  lifecycle {
    prevent_destroy = true
  }

  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_kubernetes_cluster" "k8s" {

   lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count
    ]
  }

  name                = var.cluster_name
  location            = azurerm_resource_group.k8s.location
  resource_group_name = azurerm_resource_group.k8s.name
  dns_prefix          = var.dns_prefix
  kubernetes_version  = var.kubernetes_version
  node_resource_group = var.cluster_name
  
  linux_profile {
    admin_username = var.admin_username

    ssh_key {
      key_data = data.azurerm_key_vault_secret.ssh.value
    }
  }

  default_node_pool {
    name               = "nodepool1"
    count              = var.agent_count
    vm_size            = var.vm_size
    type               = var.vm_type
    availability_zones = var.zones
    max_pods           = var.max_pods
    os_type            = "Linux"
    os_disk_size_gb    = var.os_disk_size_gb
    vnet_subnet_id     = var.vnet_subnet_id
  }

  #  lifecycle {
  #   ignore_changes = [
  #     "default_node_pool"
  #   ]
  # }

  service_principal {
    client_id     = var.azure_client_id
    client_secret = var.azure_client_secret
  }

  role_based_access_control {
    enabled = true

    azure_active_directory {
      client_app_id     = data.azurerm_key_vault_secret.aadclient.value
      server_app_id     = data.azurerm_key_vault_secret.aadserver.value
      server_app_secret = data.azurerm_key_vault_secret.aadserversecret.value
      tenant_id         = data.azurerm_key_vault_secret.aadtenant.value
    }
  }

  addon_profile {
    oms_agent {
      enabled                    = true
      log_analytics_workspace_id = var.log_analytics_workspace_id
    }
  }

  network_profile {
    load_balancer_sku  = var.lb_sku
    network_plugin     = var.network_plugin
    network_policy     = var.network_policy
    dns_service_ip     = var.dns_service_ip
    docker_bridge_cidr = var.docker_bridge_cidr
    service_cidr       = var.service_cidr
  }
}
