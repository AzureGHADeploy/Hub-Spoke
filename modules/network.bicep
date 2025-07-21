// This module deploys the network infrastructure for a Hub-Spoke architecture with Azure Firewall, VNet peering, and route tables.

@description('Location for all resources' )
param location string

@description('adminUsername for the virtual machines')
param adminUsername string = 'azureuser'

@secure()
param adminPassword string 

@description('Hub Virtual Network Name')
param hubVnetName string = 'HubVNET'

@description('Spoke 1 Virtual Network Name')
param spoke1VnetName string = 'Spoke1VNET'

@description('Spoke 2 Virtual Network Name')
param spoke2VnetName string = 'Spoke2VNET'

@description('Hub Firewall Name')
param hubFirewallName string = 'HubFirewall'

@description('Hub Firewall Public IP Name')
param hubFirewallPublicIPName string = 'HubFirewallPublicIP'

@description('Hub VNet VPN Gateway Name')
param hubVnetVPNGatewayName string = 'HubVNetVPNGateway'

@description('Hub VNet VPN Gateway Public IP Name')
param vpnpGatewayPublicIPName string = 'HubVNetVPNGatewayPublicIP'


resource HubVirtualNetwork 'Microsoft.Network/virtualNetworks@2024-07-01' = {
  name: hubVnetName
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
  name: spoke1VnetName
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
  name: spoke2VnetName
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
  name: hubFirewallName
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
        name: 'Allow_Google_Access'
        properties: {
          priority: 200
          action: {
            type: 'Allow'
          }
          rules: [
            {
              name: 'Allow_Google'
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
    natRuleCollections: [
      {
        name: 'NATRuleCollection'
        properties: {
          priority: 300
          action: {
            type: 'Dnat'
          }
          rules: [
            {
              name: 'AllowSSHToVM1inSpoke2'
              description: 'NAT rule for SSH inbound traffic to VM2 in Spoke2'
              protocols: ['TCP']
              sourceAddresses: ['*']
              destinationAddresses: [HubFirewallPublicIP.properties.ipAddress]
              destinationPorts: ['22']
              translatedAddress: VM2inSpoke2NIC.properties.ipConfigurations[0].properties.privateIPAddress
              translatedPort: '22'
            }
          ]
        }
      }
    ]
  }
}

resource HubFirewallPublicIP 'Microsoft.Network/publicIPAddresses@2024-07-01' = {
  name: hubFirewallPublicIPName
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
  name: 'Spoke1RTAssociation'
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
  name: 'Spoke2RTAssociation'
  parent: Spoke2VirtualNetwork
  properties: {
    addressPrefix: Spoke2VirtualNetwork.properties.subnets[0].properties.addressPrefix
    routeTable: {
      id: Spoke2RouteTable.id
    }
  }
}

resource vpnGateway 'Microsoft.Network/virtualNetworkGateways@2024-07-01' = {
  name: hubVnetVPNGatewayName
  location: location
  properties: {
    sku: {
      name: 'VpnGw1'
      tier: 'VpnGw1'
    }
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    vpnGatewayGeneration: 'Generation1'
    ipConfigurations: [
      {
        name: 'vnetGatewayConfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: HubVirtualNetwork.properties.subnets[2].id
          }
          publicIPAddress: {
            id: vpnpGatewayPublicIP.id
          }
        }
      }
    ]
  }
}

resource vpnpGatewayPublicIP 'Microsoft.Network/publicIPAddresses@2024-07-01' = {
  name: vpnpGatewayPublicIPName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}


resource VM1inSpoke1 'Microsoft.Compute/virtualMachines@2024-07-01' = {
  name: 'VM1inSpoke1'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2ms'
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    osProfile: {
      computerName: 'MyVM'
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: VM1inSpoke1NIC.id
        }
      ]
    }
  }
}

resource VM1inSpoke1NIC 'Microsoft.Network/networkInterfaces@2024-07-01' = {
  name: 'VM1inSpoke1NIC'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', 'Spoke1VNET', 'Subnet1-1')
          }
        }
      }
    ]
  }
}

resource VM2inSpoke2 'Microsoft.Compute/virtualMachines@2024-07-01' = {
  name: 'VM2inSpoke2'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2ms'
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    osProfile: {
      computerName: 'MyVM'
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: VM2inSpoke2NIC.id
        }
      ]
    }
  }
}


resource VM2inSpoke2NIC 'Microsoft.Network/networkInterfaces@2024-07-01' = {
  name: 'VM2inSpoke2NIC'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', 'Spoke2VNET', 'Subnet2-1')
          }
        }
      }
    ]
  }
}
