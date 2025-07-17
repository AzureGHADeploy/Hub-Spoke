param location string = resourceGroup().location

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
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', 'HubVNET', 'AzureFirewallSubnet')
          }
        }
      }
    ]
    networkRuleCollections: [
      {
        name: 'Spoke1ToSpoke2 RuleCollection'
        properties: {
          priority: 100
          action: {
            type: 'Allow'
          }
          rules: [
            {
              name: 'AllowSpoke1ToSpoke2'
              description: 'Allow traffic from Spoke1 to Spoke2'
              protocols: ['Icmp']
              sourceAddresses: [
                resourceId('Microsoft.Network/virtualNetworks/subnets', 'Spoke1VNET', 'Subnet1-1')
              ]
              destinationAddresses: [
                resourceId('Microsoft.Network/virtualNetworks/subnets', 'Spoke2VNET', 'Subnet2-1')
              ]
            }
            {
              name: 'AllowSpoke2ToSpoke1'
              description: 'Allow traffic from Spoke2 to Spoke1'
              protocols: ['Icmp']
              sourceAddresses: [
                resourceId('Microsoft.Network/virtualNetworks/subnets', 'Spoke2VNET', 'Subnet2-1')
              ]
              destinationAddresses: [
                resourceId('Microsoft.Network/virtualNetworks/subnets', 'Spoke1VNET', 'Subnet1-1')
              ]
            }
          ]
        }
      }
    ]
  }
}


output firewallprivateIP string = HubFirewall.properties.ipConfigurations[0].properties.privateIPAddress
