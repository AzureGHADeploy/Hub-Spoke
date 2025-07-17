param location string = resourceGroup().location

module networkModule 'modules/network.bicep' = {
  name: 'network'
  params: {
    location: location
  }
}
