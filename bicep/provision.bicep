var virtualNetworkName = 'vnet-labo'
var frontDoorSubnetName = 'snet-labo-frontdoor'
var containerAppsSubnetName = 'snet-labo-containerapps'
var caeName = 'cae-labo'
var privateDnsZoneName = 'privatelink.japaneast.azurecontainerapps.io-config'
var frontDoorProfileName = 'afd-labo'
var frontDoorSkuName = 'Standard_AzureFrontDoor'

var logAnalyticsWorkspaceName = 'log-core-uat'
var logAnalyticsSku = 'PerGB2018'
var applicationInsightsName = 'appinsights-core-uat'

var addressPrefixes = [
  '192.168.0.0/16'
]
var subnets = [
  {
    name: frontDoorSubnetName
    addressPrefix: '192.168.0.0/23'
  }
  {
    name: containerAppsSubnetName
    addressPrefix: '192.168.2.0/23'
  }
]

module log './modules/log.bicep' = {
  name: 'provision-log'
  params: {
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    logAnalyticsSku: logAnalyticsSku
    applicationInsightsName: applicationInsightsName
  }
}

module network 'network.bicep' = {
  name: 'provision-network'
  params: {
    virtualNetworkName: virtualNetworkName
    addressPrefixes: addressPrefixes
    subnets: subnets
  }
}

module cae './modules/cae.bicep' = {
  name: 'provision-cae'
  params: {
    caeName: caeName
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    applicationInsightsName: applicationInsightsName
  }
  dependsOn: [
    network
    log
  ]
}

module pdns './modules/pdns.bicep' = {
  name: 'provision-pdns'
  params: {
    privateDnsZoneName: privateDnsZoneName
    virtualNetworkName: virtualNetworkName
  }
  dependsOn: [
    cae
  ]
}
module pep './modules/pep.bicep' = {
  name: 'provision-pep'
  params: {
    caeName: caeName
    virtualNetworkName: virtualNetworkName
    privateDnsZoneName: privateDnsZoneName
    subnetName: containerAppsSubnetName
  }
  dependsOn: [
    pdns
  ]
}

module ca './modules/ca.bicep' = {
  name: 'provision-ca'
  params: {
    caeName: caeName
    containerAppName: 'ca-test-app'
  }
  dependsOn: [
    pdns
  ]
}

module afd 'afd.bicep' = {
  name: 'provision-afd'
  params: {
    frontDoorProfileName: frontDoorProfileName
    frontDoorSkuName: frontDoorSkuName
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
  }
  dependsOn: [
    network
    log
  ]
}
