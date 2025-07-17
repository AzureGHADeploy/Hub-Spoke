param location string = resourceGroup().location

@secure()
param adminpassword string

module networkModule 'modules/network.bicep' = {
  name: 'network'
  params: {
    location: location
  }
}

module computeModule 'modules/compute.bicep' = {
  name: 'compute'
  params: {
    location: location
    adminPassword: adminpassword
  }
}
