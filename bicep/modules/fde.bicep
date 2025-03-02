param location string = 'global'

param frontDoorProfileName string

param prefix string
param originHostName string
param originHostHeader string
param probePath string = '/'
param managedEnvironmentsId string

var endpointName = '${prefix}-endpoint'
var routeName = '${prefix}-route'
var originGroup = {
  name: '${prefix}-origingroup'
  probePath: probePath
}
var origins = [{
  name: '${prefix}-origin'
  hostName: originHostName
  originHostHeader: originHostHeader
  priority: 1
  weight: 1000
  sharedPrivateLinkResource: {
    privateLink: {
      id: managedEnvironmentsId
    }
    groupId: 'managedEnvironments'
    privateLinkLocation: 'japaneast'
    requestMessage: 'AFD Private Link Request'
  }
}]

resource frontDoorProfile 'Microsoft.Cdn/profiles@2024-09-01' existing = {
  name: frontDoorProfileName
}

resource endpoint 'Microsoft.Cdn/profiles/afdEndpoints@2024-09-01' = {
  parent: frontDoorProfile
  name: endpointName
  location: location
  properties: {
    enabledState: 'Enabled'
  }
}

resource originGroupResource 'Microsoft.Cdn/profiles/originGroups@2024-09-01' = {
  parent: frontDoorProfile
  name: originGroup.name
  properties: {
    loadBalancingSettings: {
      sampleSize: 4
      successfulSamplesRequired: 3
    }
    healthProbeSettings: {
      probePath: originGroup.probePath
      probeRequestType: 'HEAD'
      probeProtocol: 'Https'
      probeIntervalInSeconds: 100
    }
  }
}


resource originResources 'Microsoft.Cdn/profiles/originGroups/origins@2024-09-01' = [for (origin, index) in origins: {
  parent: originGroupResource
  name: origin.name
  properties: {
    hostName: origin.hostName
    httpsPort: 443
    originHostHeader: origin.originHostHeader
    priority: origin.priority
    weight: origin.weight
    sharedPrivateLinkResource: origin.sharedPrivateLinkResource
    enforceCertificateNameCheck: true
  }
  dependsOn: index == 0 ? [] : [origins[index - 1]]
}]

resource routeResource 'Microsoft.Cdn/profiles/afdEndpoints/routes@2024-09-01' = {
  parent: endpoint
  name: routeName
  dependsOn: [
    originResources
  ]
  properties: {
    originGroup: {
      id: originGroupResource.id
    }
    supportedProtocols: [
      'Https'
    ]
    patternsToMatch: [
      '/*'
    ]
    forwardingProtocol: 'HttpsOnly'
    linkToDefaultDomain: 'Enabled'
    httpsRedirect: 'Enabled'
  }
}

output endpointId string = endpoint.id
