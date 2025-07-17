param location string

param FirewallPrivateIP string

resource HubVirtualNetwork 'Microsoft.Network/virtualNetworks@2024-07-01' = {
  name: 'HubVNET'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'AzurebastionSubnet'
        properties: {
          addressPrefix: '10.0.0.0/26'
        }
      }
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: '10.0.0.64/26'
        }
      }
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: '10.0.0.128/27'
        }
      }
    ]
  }
}

resource Spoke1VirtualNetwork 'Microsoft.Network/virtualNetworks@2024-07-01' = {
  name: 'Spoke1VNET'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.1.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'Subnet1-1'
        properties: {
          addressPrefix: '10.1.0.0/26'
        }
      }
    ]
  }
}

resource HubToSpoke1VnetPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-07-01' = {
  name: 'HubToSpoke1VnetPeering'
  parent: HubVirtualNetwork
  properties: {
    allowVirtualNetworkAccess: true
    remoteVirtualNetwork: {
      id: Spoke1VirtualNetwork.id
    }
    useRemoteGateways: false
    allowForwardedTraffic: false
    allowGatewayTransit: false
  }
}

resource Spoke1ToHubVnetPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-07-01' = {
  name: 'Spoke1ToHubVnetPeering'
  parent: Spoke1VirtualNetwork
  properties: {
    allowVirtualNetworkAccess: true
    remoteVirtualNetwork: {
      id: HubVirtualNetwork.id
    }
    useRemoteGateways: false
    allowForwardedTraffic: false
    allowGatewayTransit: false
  }
}


resource Spoke2VirtualNetwork 'Microsoft.Network/virtualNetworks@2024-07-01' = {
  name: 'Spoke2VNET'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.2.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'Subnet2-1'
        properties: {
          addressPrefix: '10.2.0.0/26'
        }
      }
    ]
  }
}

resource HubToSpoke2VnetPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-07-01' = {
  name: 'HubToSpoke2VnetPeering'
  parent: HubVirtualNetwork
  properties: {
    allowVirtualNetworkAccess: true
    remoteVirtualNetwork: {
      id: Spoke2VirtualNetwork.id
    }
    useRemoteGateways: false
    allowForwardedTraffic: false
    allowGatewayTransit: false
  }
}

resource spoke2ToHubVnetPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-07-01' = {
  name: 'Spoke2ToHubVnetPeering'
  parent: Spoke2VirtualNetwork
  properties: {
    allowVirtualNetworkAccess: true
    remoteVirtualNetwork: {
      id: HubVirtualNetwork.id
    }
    useRemoteGateways: false
    allowForwardedTraffic: false
    allowGatewayTransit: false
  }
}

resource Spoke1RouteTable 'Microsoft.Network/routeTables@2024-07-01' = {
  name: 'Spoke1RouteTable'
  location: location
  properties: {
    routes: [
      {
        name: 'RouteToHub'
        properties: {
          addressPrefix: Spoke1VirtualNetwork.properties.subnets[0].properties.addressPrefix
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: FirewallPrivateIP
        }
      }
    ]
  }
}

resource Spoke1RouteTableAssociation 'Microsoft.Network/virtualNetworks/subnets@2024-07-01' = {
  name: 'Subnet1-1'
  parent: Spoke1VirtualNetwork
  properties: {
    routeTable: {
      id: Spoke1RouteTable.id
    }
  }
}

resource Spoke2RouteTable 'Microsoft.Network/routeTables@2024-07-01' = {
  name: 'Spoke2RouteTable'
  location: location
  properties: {
    routes: [
      {
        name: 'RouteToHub'
        properties: {
          addressPrefix: Spoke2VirtualNetwork.properties.subnets[0].properties.addressPrefix
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: FirewallPrivateIP
        }
      }
    ]
  }
}

resource Spoke2RouteTableAssociation 'Microsoft.Network/virtualNetworks/subnets@2024-07-01' = {
  name: 'Subnet2-1'
  parent: Spoke2VirtualNetwork
  properties: {
    routeTable: {
      id: Spoke2RouteTable.id
    }
  }
}
