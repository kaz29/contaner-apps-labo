param location string = resourceGroup().location

param caeName string
param containerAppName string
param isExternalIngress bool = true

@allowed([
  'multiple'
  'single'
])
param revisionMode string = 'single'

resource environment 'Microsoft.App/managedEnvironments@2022-03-01' existing = {
  name: caeName
}

resource containerApp 'Microsoft.App/containerApps@2023-04-01-preview' = {
  name: containerAppName
  location: location
  identity: {
      type: 'SystemAssigned'
    }
  properties: {
    managedEnvironmentId: environment.id
    configuration: {
      activeRevisionsMode: revisionMode
      dapr:{
        enabled:false
      }
      ingress: {
        external: isExternalIngress
        targetPort: 80
        transport: 'auto'
        allowInsecure: false
      }
      secrets: []
      registries: []
    }
    template: {
      containers: [
        {
          image: 'nginx:latest'
          name: containerAppName
          resources: {
            cpu: any('0.5')
            memory: '1Gi'
          }
          env: []
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 5
        rules: [
          {
            name: 'http-scaling-rule'
            http: {
              metadata: {
                concurrentRequests: '60'
              }
            }
          }
        ]
      }
    }
  }
}

output fqdn string = containerApp.properties.configuration.ingress.fqdn
