@description('location')
param location string = resourceGroup().location

@minLength(3)
@maxLength(24)
param storageAccountName string
param queueName string

var sku = 'Standard_LRS'
var kind string = 'StorageV2'

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: sku
  }
  kind: kind
  properties: {
    minimumTlsVersion: 'TLS1_2'
  }
}

resource queueService 'Microsoft.Storage/storageAccounts/queueServices@2025-01-01' = {
  parent: storageAccount
  name: 'default'
  properties: {}
}

resource queue 'Microsoft.Storage/storageAccounts/queueServices/queues@2025-01-01' = {
  parent: queueService
  name: queueName
}

@description('Storage Account name')
output storageAccountName string = storageAccount.name

@description('Storage Account resource ID')
output storageAccountId string = storageAccount.id

@description('Storage Account primary key (use carefully)')
@secure()
output storageAccountKey string = storageAccount.listKeys().keys[0].value

