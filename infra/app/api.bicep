// Copyright 2024 Heath Stewart.
// Licensed under the MIT License. See LICENSE.txt in the project root for license information.

@minLength(1)
param name string
param location string = resourceGroup().location
param tags object = {}
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
var storageConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${storage.name};AccountKey=${storage.listKeys().keys[0].value};EndpointSuffix=core.windows.net'

resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: substring('${name}${resourceToken}', 0, 24)
  location: location
  tags: tags
  sku: {
    name: storageAccountType
  }
  kind: 'StorageV2'
  properties: {
    defaultToOAuthAuthentication: true
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
  }
}

resource plan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: 'asp-${name}-${resourceToken}'
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

resource func 'Microsoft.Web/sites@2023-12-01' = {
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
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: storageConnectionString
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: '${name}${uniqueString(storage.name, storage.location)}'
        }
        {
          name: 'AzureWebJobsStorage'
          value: storageConnectionString
        }
      ]
    })
    httpsOnly: true
  }

  resource ftp 'basicPublishingCredentialsPolicies' = {
    name: 'ftp'
    properties: {
      allow: false
    }
  }

  resource scm 'basicPublishingCredentialsPolicies' = {
    name: 'scm'
    properties: {
      allow: false
    }
  }

  resource slot 'slots@2023-12-01' = {
    name: 'test'
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
            name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
            value: storageConnectionString
          }
          {
            name: 'WEBSITE_CONTENTSHARE'
            value: '${name}test${uniqueString(storage.name, storage.location)}'
          }
          {
            name: 'AzureWebJobsStorage'
            value: storageConnectionString
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

output name string = func.name
output url string = 'https://${func.properties.defaultHostName}'
