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

resource SpokeVirtualNetwork 'Microsoft.Network/virtualNetworks@2024-07-01' = {
  name: 'SpokeVNET'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.1.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.1.0.0/26'
        }
      }
    ]
  }
}
