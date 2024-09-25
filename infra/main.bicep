// Copyright 2024 Heath Stewart.
// Licensed under the MIT License. See LICENSE.txt in the project root for license information.

targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

@description('Override the name of the resource group')
param resourceGroupName string = 'rg-${environmentName}'

@description('User principal ID')
param principalId string = ''

@description('Storage Account type')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
])
param storageAccountType string = 'Standard_LRS'

@description('How long until the resource group is cleaned up by Azure SDK engineering team automated processes.')
param deleteAfterTime string = dateTimeAdd(utcNow('o'), 'P1D')

@description('User-defined tags on the resource group')
param tags object = {}

var allTags = union(
  {
    'azd-env-name': environmentName
  },
  tags
)

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: union(allTags, { DeleteAfter: deleteAfterTime })
}

module api './app/api.bicep' = {
  scope: rg
  name: 'api'
  params: {
    name: environmentName
    location: location
    tags: allTags
    storageAccountType: storageAccountType
  }
}

output AZURE_FUNCTIONAPP_NAME string = api.outputs.name
output AZURE_FUNCTIONAPP_URL string = api.outputs.url
output AZURE_LOCATION string = location
output AZURE_PRINCIPAL_ID string = principalId
output AZURE_RESOURCE_GROUP string = resourceGroupName
output AZURE_SUBSCRIPTION_ID string = subscription().subscriptionId
output AZURE_TENANT_ID string = tenant().tenantId
