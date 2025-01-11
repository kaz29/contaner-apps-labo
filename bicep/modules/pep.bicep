param location string = resourceGroup().location

param caeName string
param virtualNetworkName string
param privateDnsZoneName string
param subnetName string

var privateEndPointName = 'pep-${caeName}'

var connections = [
  {
    name: privateEndPointName
    properties: {
      privateLinkServiceId: cae.id
      groupIds: [
        'managedEnvironments'
      ]
      privateLinkServiceConnectionState: {
        status: 'Approved'
        description: 'Auto-approved'
        actionsRequired: 'None'
      }
    }
  }
]
var privateDnsZoneConfigs = [
  {
    name: replace(privateDnsZoneName, '.', '-')
    properties: {
      privateDnsZoneId: privateDNSZone.id
    }
  }
]

resource privateDNSZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: privateDnsZoneName
}
resource cae 'Microsoft.App/managedEnvironments@2024-03-01' existing = {
  name: caeName
}

resource vnet 'Microsoft.Network/virtualNetworks@2024-01-01' existing = {
  name: virtualNetworkName
}

resource pep 'Microsoft.Network/privateEndpoints@2024-01-01' = {
  name: privateEndPointName
  location: location
  properties: {
    privateLinkServiceConnections: connections
    customNetworkInterfaceName: '${privateEndPointName}-nic'
    subnet: {
      id: '${vnet.id}/subnets/${subnetName}'
    }
    ipConfigurations: []
  }
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-01-01' = {
  parent: pep
  name: '${privateEndPointName}-default'
  properties: {
    privateDnsZoneConfigs: privateDnsZoneConfigs
  }
}
