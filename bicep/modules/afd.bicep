param location string = 'global'

param frontDoorProfileName string
@allowed([
  'Standard_AzureFrontDoor'
  'Premium_AzureFrontDoor'
])
param frontDoorSkuName string

resource frontDoorProfile 'Microsoft.Cdn/profiles@2024-06-01-preview' = {
  name: frontDoorProfileName
  location: location
  sku: {
    name: frontDoorSkuName
  }
}
