var caeName = 'cae-labo'
var frontDoorProfileName = 'afd-labo'
var frontDoorSkuName = 'Premium_AzureFrontDoor'

var logAnalyticsWorkspaceName = 'log-core-uat'
var logAnalyticsSku = 'PerGB2018'
var applicationInsightsName = 'appinsights-core-uat'

module log './modules/log.bicep' = {
  name: 'provision-log'
  params: {
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    logAnalyticsSku: logAnalyticsSku
    applicationInsightsName: applicationInsightsName
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
    log
  ]
}

module ca './modules/ca.bicep' = {
  name: 'provision-ca'
  params: {
    caeName: caeName
    containerAppName: 'ca-test-app'
  }
  dependsOn: [
    cae
  ]
}

module afd './modules/afd.bicep' = {
  name: 'provision-afd'
  params: {
    frontDoorProfileName: frontDoorProfileName
    frontDoorSkuName: frontDoorSkuName
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
  }
  dependsOn: [
    log
    ca
  ]
}

module fde './modules/fde.bicep' = {
  name: 'provision-fde'
  params: {
    frontDoorProfileName: frontDoorProfileName
    prefix: 'test-app'
    originHostName: ca.outputs.fqdn
    originHostHeader: ca.outputs.fqdn
    managedEnvironmentsId: cae.outputs.managedEnvironmentsId
  }
  dependsOn: [
    afd
  ]
}
