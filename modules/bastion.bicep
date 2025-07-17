param location string

resource AzureBastion 'Microsoft.Network/bastionHosts@2024-07-01' = {
  name: 'AzureBastion'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'BastionIpConfiguration'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', 'HubVNET', 'AzureBastionSubnet')
          }
          publicIPAddress: {
            id: AzureBastionPublicIP.id
          }
        }
      }
    ]
  }
}

resource AzureBastionPublicIP 'Microsoft.Network/publicIPAddresses@2024-07-01' = {
  name: 'AzureBastionPublicIP'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}
