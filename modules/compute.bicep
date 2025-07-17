param location string

param adminUsername string = 'azureuser'
@secure()
param adminPassword string 

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
