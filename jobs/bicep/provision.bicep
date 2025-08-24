param location string = resourceGroup().location

param containerImageName string

var storageAccountName = 'stqueueexample'
var queueName = 'queue-job-example'
var environmentName = 'cae-queue-job-example'
var containerAppName = 'ca-queue-job-example'

module storage 'modules/st.bicep' = {
  params: {
    storageAccountName: storageAccountName
    queueName: queueName
  }
}

var storageConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${storage.outputs.storageAccountName};AccountKey=${storage.outputs.storageAccountKey};EndpointSuffix=${az.environment().suffixes.storage}'

resource idResource 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-07-31-preview' = {
  name: 'id-queue-job-example'
  location: location
}

module kv 'modules/kv.bicep' = {
  name: 'queue-job-example-kv'
  params: {
    location: location
    keyVaultName: 'queue-job-example-kv'
    caQueueExampleObjectId: idResource.properties.principalId
    queueConnectionString: storageConnectionString
  }
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: 'log-queue-log-example'
  location: location
  properties: any({
    retentionInDays: 30
    features: {
      searchVersion: 1
      legacy: 0
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    sku: {
      name: 'PerGB2018'
    }
  })
}

resource environment 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: environmentName
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
    zoneRedundant: false
    peerAuthentication: {
      mtls: {
        enabled: false
      }
    }
    workloadProfiles: [{
      name: 'Consumption'
      workloadProfileType: 'Consumption'
    }]
    peerTrafficConfiguration: {
      encryption: {
        enabled: false
      }
    }
  }
}

@description('コンテナレプリカの最大タイムアウト（秒）')
param replicaTimeout int = 300

@description('最大再試行回数')
param replicaRetryLimit int = 0

@description('最小実行数')
param minExecutions int = 0

@description('最大実行数')
param maxExecutions int = 10

@description('ポーリング間隔（秒）')
param pollingInterval int = 30

@description('コンテナのCPUリソース')
param cpu string = '0.25'

@description('コンテナのメモリリソース')
param memory string = '0.5Gi'

@description('環境変数')
var environmentVariables = [
  {
    name: 'QUEUE_CONNECTION_STRING'
    secretRef: 'queue-connection-string'
  }
  {
    name: 'QUEUE_NAME'
    value: queueName
  }
]
@description('シークレット')
var secrets array = [
  {
    name: 'queue-connection-string'
    keyVaultUrl: kv.outputs.secretUris[0].uri
    identity: idResource.id
  }
]

resource containerApp 'Microsoft.App/jobs@2025-02-02-preview' = {
  name: containerAppName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${idResource.id}': {}
    }
  }
  properties: {
    environmentId: environment.id
    configuration: {
      triggerType: 'Event'
      replicaTimeout: replicaTimeout
      replicaRetryLimit: replicaRetryLimit
      eventTriggerConfig: {
        scale: {
          minExecutions: minExecutions
          maxExecutions: maxExecutions
          pollingInterval: pollingInterval
          rules: [
            {
              name: 'queue'
              type: 'azure-queue'
              metadata: {
                queueName: queueName
                queueLength: '1'
                accountName: storageAccountName
              }
              auth: [
                {
                  secretRef: 'queue-connection-string'
                  triggerParameter: 'connection'
                }
              ]
            }
          ]
        }
        parallelism: 1
        replicaCompletionCount: 1
      }
      secrets: secrets
    }
    template: {
      containers: [
        {
          image: containerImageName
          name: containerAppName
          resources: {
            cpu: json(cpu)
            memory: memory
          }
          env: environmentVariables
        }
      ]
    }
  }
}
