param location string = resourceGroup().location

@export()
type subnet = {
  name: string
  addressPrefix: string
}

param virtualNetworkName string
param addressPrefixes string[]
param subnets subnet[]

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-01-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: addressPrefixes
    }
    subnets: [for subnet in subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.addressPrefix
      }
    }]
    virtualNetworkPeerings: []
  }
}
