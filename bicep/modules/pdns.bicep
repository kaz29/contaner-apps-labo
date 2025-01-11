
param privateDnsZoneName string
param virtualNetworkName string

resource vnet 'Microsoft.Network/virtualNetworks@2024-01-01' existing = {
  name: virtualNetworkName
}

resource privateDNSZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsZoneName
  location: 'global'
  tags: {
    displayName: '${privateDnsZoneName} Private DNS Zone'
    'hidden-title': '${privateDnsZoneName} Private DNS Zone'
  }
}

resource privateDNSzoneNetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDNSZone
  name: 'link_to_${virtualNetworkName}'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}
