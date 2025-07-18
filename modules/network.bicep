param location string

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
          addressPrefix: '10.1.0.0/24'
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
    allowForwardedTraffic: true
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
          addressPrefix: '10.2.0.0/24'
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
    allowForwardedTraffic: true
    allowGatewayTransit: false
  }
}

resource HubFirewall 'Microsoft.Network/azureFirewalls@2024-07-01' = {
  name: 'HubFirewall'
  location: location
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Standard'
    }
    ipConfigurations: [
      {
        name: 'FirewallIpConfiguration'
        properties: {
          subnet: {
            id: HubVirtualNetwork.properties.subnets[1].id
          }
          publicIPAddress: {
            id: HubFirewallPublicIP.id
          }
        }
      }
    ]
    networkRuleCollections: [
      {
        name: 'Spoke1ToSpoke2RuleCollection'
        properties: {
          priority: 100
          action: {
            type: 'Allow'
          }
          rules: [
            {
              name: 'AllowSpoke1ToSpoke2'
              description: 'Allow traffic from Spoke1 to Spoke2'
              protocols: ['ICMP']
              sourceAddresses: [
                Spoke1VirtualNetwork.properties.subnets[0].properties.addressPrefix
              ]
              destinationAddresses: [
                Spoke2VirtualNetwork.properties.subnets[0].properties.addressPrefix
              ]
              destinationPorts: [
                '*'
              ]
            }
            {
              name: 'AllowSpoke2ToSpoke1'
              description: 'Allow traffic from Spoke2 to Spoke1'
              protocols: ['ICMP']
              sourceAddresses: [
                Spoke2VirtualNetwork.properties.subnets[0].properties.addressPrefix
              ]
              destinationAddresses: [
                Spoke1VirtualNetwork.properties.subnets[0].properties.addressPrefix
              ]
              destinationPorts: [
                '*'
              ]
            }
          ]
        }
      }
    ]
    applicationRuleCollections: [
      {
        name: 'Allow Google Access'
        properties: {
          priority: 200
          action: {
            type: 'Allow'
          }
          rules: [
            {
              name: 'Allow Google'
              description: 'Allow outbound Google access'
              sourceAddresses: [ Spoke1VirtualNetwork.properties.subnets[0].properties.addressPrefix ]
              protocols: [
                {
                  protocolType: 'Http'
                  port: 80
                }
                {
                  protocolType: 'Https'
                  port: 443
                }
              ]
              targetFqdns: [
                'www.google.com'                
              ]
            }
          ]
        }
      }
    ]
  }
}

resource HubFirewallPublicIP 'Microsoft.Network/publicIPAddresses@2024-07-01' = {
  name: 'HubFirewallPublicIP'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
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
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: HubFirewall.properties.ipConfigurations[0].properties.privateIPAddress
        }
      }
    ]
  }
}

resource Spoke1RouteTableAssociation 'Microsoft.Network/virtualNetworks/subnets@2024-07-01' = {
  name: 'Subnet1-1'
  parent: Spoke1VirtualNetwork
  properties: {
    addressPrefix: Spoke1VirtualNetwork.properties.subnets[0].properties.addressPrefix
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
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: HubFirewall.properties.ipConfigurations[0].properties.privateIPAddress
        }
      }
    ]
  }
}

resource Spoke2RouteTableAssociation 'Microsoft.Network/virtualNetworks/subnets@2024-07-01' = {
  name: 'Subnet2-1'
  parent: Spoke2VirtualNetwork
  properties: {
    addressPrefix: Spoke2VirtualNetwork.properties.subnets[0].properties.addressPrefix
    routeTable: {
      id: Spoke2RouteTable.id
    }
  }
}
