param location string = 'global'

param frontDoorProfileName string
@allowed([
  'Standard_AzureFrontDoor'
  'Premium_AzureFrontDoor'
])
param frontDoorSkuName string
param logAnalyticsWorkspaceName string

param accessLogRetentionPolicy object = {
  enabled: false
  days: 0
}
param wafLogRetentionPolicy object = {
  enabled: false
  days: 0
}
param healthProveLogRetentionPolicy object = {
  enabled: false
  days: 0
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  scope: resourceGroup()
  name: logAnalyticsWorkspaceName
}

resource frontDoorProfile 'Microsoft.Cdn/profiles@2024-06-01-preview' = {
  name: frontDoorProfileName
  location: location
  sku: {
    name: frontDoorSkuName
  }
}

resource frontDoorDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: frontDoorProfile
  name: '${frontDoorProfileName}-diagnostics'
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        category: 'FrontdoorAccessLog'
        enabled: true
        retentionPolicy: accessLogRetentionPolicy
      }
      {
        category: 'FrontdoorWebApplicationFirewallLog'
        enabled: true
        retentionPolicy: wafLogRetentionPolicy
      }
      {
        category: 'FrontdoorHealthProbeLog'
        enabled: true
        retentionPolicy: healthProveLogRetentionPolicy
      }
    ]
  }
}
