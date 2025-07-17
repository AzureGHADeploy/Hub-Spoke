param location string = resourceGroup().location


@secure()
param adminpassword string

module networkModule 'modules/network.bicep' = {
  name: 'network'
  params: {
    location: location
    FirewallPrivateIP: firewallModule.outputs.firewallprivateIP
  }
}

module computeModule 'modules/compute.bicep' = {
  name: 'compute'
  params: {
    location: location
    adminPassword: adminpassword
  }
}

module firewallModule 'modules/firewall.bicep' = {
  name: 'firewall'
  params: {
    location: location
  }
}
