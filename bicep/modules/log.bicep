param location string = resourceGroup().location

param logAnalyticsWorkspaceName string
param applicationInsightsName string

param logAnalyticsSku string

param applicationInsightsKind string = 'web'
param applicationInsightsType string = 'web'

param retentionInDays int = 30

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: any({
    retentionInDays: retentionInDays
    features: {
      searchVersion: 1
      legacy: 0
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    sku: {
      name: logAnalyticsSku
    }
  })
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  kind: applicationInsightsKind
  properties: { 
    Application_Type: applicationInsightsType
    WorkspaceResourceId:logAnalyticsWorkspace.id
    Flow_Type: 'Bluefield'
    Request_Source: 'rest'
  }
}
