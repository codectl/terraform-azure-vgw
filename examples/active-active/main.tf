module "naming" {
  source  = "codectl/naming/azure"
  version = "~> 0.1"

  suffix = ["demo", "dev"]
}

module "regions" {
  source  = "codectl/locations/azure"
  version = "~> 1.0"

  location = {
    primary = "westeurope"
  }
}

module "rg" {
  source  = "codectl/rg/azure"
  version = "~> 1.0"

  groups = {
    demo = {
      name     = module.naming.resource_group.name_unique
      location = module.regions.location.primary.name
    }
  }
}

module "network" {
  source  = "codectl/vnet/azure"
  version = "~> 1.0"

  vnet = {
    name                = module.naming.virtual_network.name
    address_space       = ["10.18.0.0/16"]
    location            = module.rg.groups.demo.location
    resource_group_name = module.rg.groups.demo.name

    subnets = {
      sn1 = {
        name             = "GatewaySubnet"
        address_prefixes = ["10.18.1.0/24"]
      }
    }
  }
}

module "public_ip" {
  source  = "codectl/pip/azure"
  version = "~> 1.0"

  resource_group_name = module.rg.groups.demo.name
  location            = module.rg.groups.demo.location

  public_ips = {
    pip1 = {
      name              = "${module.naming.public_ip.name}-vgw-01"
      allocation_method = "Static"
      sku               = "Standard"
      zones             = ["1", "2", "3"]
    }
    pip2 = {
      name              = "${module.naming.public_ip.name}-vgw-02"
      allocation_method = "Static"
      sku               = "Standard"
      zones             = ["1", "2", "3"]
    }
  }
}

module "vgw" {
  source  = "codectl/vgw/azure"
  version = "~> 1.0"

  gateway = {
    name                = module.naming.virtual_network_gateway.name_unique
    location            = module.rg.groups.demo.location
    resource_group_name = module.rg.groups.demo.name
    sku                 = "VpnGw1"
    type                = "Vpn"
    active_active       = true

    ip_configurations = {
      config1 = {
        name                 = "config1"
        subnet_id            = module.network.subnets.sn1.id
        public_ip_address_id = module.public_ip.public_ips.pip1.id
      },
      config2 = {
        name                 = "config2"
        subnet_id            = module.network.subnets.sn1.id
        public_ip_address_id = module.public_ip.public_ips.pip2.id
      }
    }
  }
}
