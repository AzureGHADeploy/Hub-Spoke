param location string = resourceGroup().location


@secure()
param adminpassword string

module networkModule 'modules/network.bicep' = {
  name: 'network'
  params: {
    location: location  
    adminPassword: adminpassword
  }
}

 module bastionModule 'modules/bastion.bicep' = {
  name: 'bastion'
  dependsOn: [
    networkModule
  ]
  params: {
    location: location
  }
}

