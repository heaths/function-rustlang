// Copyright 2024 Heath Stewart.
// Licensed under the MIT License. See LICENSE.txt in the project root for license information.

@minLength(1)
param name string
param location string = resourceGroup().location
param tags object = {}
param principalId string
param storageAccountType string

var functionExtensionVersion = '~4'
var functionRuntime = 'custom'
var resourceToken = toLower(uniqueString(subscription().id, name, location))
var siteConfig = {
  cors: {
    allowedOrigins: [
      'https://portal.azure.com'
    ]
  }
  linuxFxVersion: ''
  minTlsVersion: '1.2'
}
var storageName = '${name}${resourceToken}'

resource storage 'Microsoft.Storage/storageAccounts@2025-01-01' = {
  name: substring(storageName, 0, min(length(storageName), 24))
  location: location
  tags: tags
  sku: {
    name: storageAccountType
  }
  kind: 'StorageV2'
  properties: {
    defaultToOAuthAuthentication: true
    minimumTlsVersion: 'TLS1_2'
    publicNetworkAccess: 'Enabled'
    supportsHttpsTrafficOnly: true
  }

  resource blob 'blobServices' = {
    name: 'default'

    resource production 'containers' = {
      name: 'production'
      properties: {
        publicAccess: 'None'
      }
    }

    resource staging 'containers' = {
      name: 'staging'
      properties: {
        publicAccess: 'None'
      }
    }
  }
}

var blobDataContributorDef = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
)
var blobDataReaderDef = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1'
)

resource blobDataContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(name, func.name, principalId, blobDataContributorDef)
  scope: storage
  properties: {
    principalId: principalId
    roleDefinitionId: blobDataContributorDef
  }
}

resource blobDataReader 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(name, func.name, 'SystemAssigned', blobDataReaderDef)
  scope: storage
  properties: {
    principalId: func.identity.principalId
    roleDefinitionId: blobDataReaderDef
  }
}

resource plan 'Microsoft.Web/serverfarms@2024-11-01' = {
  name: 'plan${name}${resourceToken}'
  location: location
  tags: tags
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

resource func 'Microsoft.Web/sites@2024-11-01' = {
  name: name
  location: location
  tags: tags
  kind: 'functionapp,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: plan.id
    siteConfig: union(siteConfig, {
      appSettings: [
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: functionExtensionVersion
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: functionRuntime
        }
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: uri(storage.properties.primaryEndpoints.blob, '${storage::blob::production.name}/deploy.zip')
        }
      ]
    })
    httpsOnly: true
  }

  resource funcFtp 'basicPublishingCredentialsPolicies' = {
    name: 'ftp'
    properties: {
      allow: false
    }
  }

  resource funcScm 'basicPublishingCredentialsPolicies' = {
    name: 'scm'
    properties: {
      allow: false
    }
  }

  resource slot 'slots' = {
    name: 'staging'
    location: location
    properties: {
      serverFarmId: plan.id
      siteConfig: union(siteConfig, {
        appSettings: [
          {
            name: 'FUNCTIONS_EXTENSION_VERSION'
            value: functionExtensionVersion
          }
          {
            name: 'FUNCTIONS_WORKER_RUNTIME'
            value: functionRuntime
          }
          {
            name: 'WEBSITE_RUN_FROM_PACKAGE'
            value: uri(storage.properties.primaryEndpoints.blob, '${storage::blob::staging.name}/deploy.zip')
          }
        ]
      })
      httpsOnly: true
    }

    resource slotFtp 'basicPublishingCredentialsPolicies' = {
      name: 'ftp'
      properties: {
        allow: false
      }
    }

    resource slotScm 'basicPublishingCredentialsPolicies' = {
      name: 'scm'
      properties: {
        allow: false
      }
    }
  }
}

output AZURE_STORAGE_URL string = storage.properties.primaryEndpoints.blob
output func object = {
  name: func.name
  container: storage::blob::production.name
  url: 'https://${func.properties.defaultHostName}'
}
output slot object = {
  name: func::slot.name
  container: storage::blob::staging.name
  url: 'https://${func::slot.properties.defaultHostName}'
}
