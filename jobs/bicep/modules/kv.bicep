param location string = resourceGroup().location
param tenantId string = subscription().tenantId

param keyVaultName string
param caQueueExampleObjectId string
param queueConnectionString string

param enabledForDeployment bool = false
param enabledForDiskEncryption bool = false
param enabledForTemplateDeployment bool = false

@allowed([
  'standard'
  'premium'
])
param skuName string = 'standard'

param secrets array = [
  {
    name: 'queueConnectionString'
    properties: {
      value: queueConnectionString
    }
  }
]

@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Enabled'

param networkAcls object = {
  bypass: 'AzureServices'
  defaultAction: 'Allow'
  ipRules: []
  virtualNetworkRules: []
}

param accessPolicies array = [
  {
    objectId: caQueueExampleObjectId
    tenantId: tenantId
    permissions: {
      secrets: ['get']
    }
  }
]

resource kv 'Microsoft.KeyVault/vaults@2024-12-01-preview' = {
  name: keyVaultName
  location: location
  properties: {
    enabledForDeployment: enabledForDeployment
    enabledForDiskEncryption: enabledForDiskEncryption
    enabledForTemplateDeployment: enabledForTemplateDeployment
    tenantId: tenantId
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    accessPolicies: accessPolicies
    sku: {
      name: skuName
      family: 'A'
    }
    networkAcls: networkAcls
    publicNetworkAccess: publicNetworkAccess
  }
}

resource secretResources 'Microsoft.KeyVault/vaults/secrets@2024-12-01-preview' = [for secret in secrets: {
  parent: kv
  name: secret.name
  properties: secret.properties
}]

@description('Key Vault resource ID')
output keyVaultId string = kv.id

@description('Key Vault name')
output keyVaultName string = kv.name

@description('Key Vault URI')
output keyVaultUri string = kv.properties.vaultUri

@description('Secret URIs array for referencing in other modules')
output secretUris array = [for (secret, i) in secrets: {
  name: secret.name
  uri: '${kv.properties.vaultUri}secrets/${secret.name}'
}]

