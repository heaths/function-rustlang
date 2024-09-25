// Copyright 2024 Heath Stewart.
// Licensed under the MIT License. See LICENSE.txt in the project root for license information.

@minLength(1)
param name string
param location string = resourceGroup().location
param tags object = {}
param storageAccountType string
var siteConfig = {
  appSettings: [
    {
      name: 'FUNCTIONS_EXTENSION_VERSION'
      value: '~4'
    }
    {
      name: 'FUNCTIONS_WORKER_RUNTIME'
      value: 'custom'
    }
    {
      name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
      value: 'DefaultEndpointsProtocol=https;AccountName=${storage.name};AccountKey=${storage.listKeys().keys[0].value};EndpointSuffix=core.windows.net'
    }
    {
      name: 'AzureWebJobsStorage'
      value: 'DefaultEndpointsProtocol=https;AccountName=${storage.name};AccountKey=${storage.listKeys().keys[0].value};EndpointSuffix=core.windows.net'
    }
  ]
  cors: {
    allowedOrigins: [
      'https://portal.azure.com'
    ]
  }
  linuxFxVersion: 'custom|~4'
  minTlsVersion: '1.2'
}

resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: 'st${name}'
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
  name: 'plan-${name}'
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
  name: 'func-${name}'
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
          name: 'WEBSITE_CONTENTSHARE'
          value: '${name}${uniqueString(storage.name, storage.location)}'
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
            name: 'WEBSITE_CONTENTSHARE'
            value: '${name}test${uniqueString(storage.name, storage.location)}'
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

output url string = 'https://${func.properties.defaultHostName}'
