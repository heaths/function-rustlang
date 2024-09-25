// Copyright 2024 Heath Stewart.
// Licensed under the MIT License. See LICENSE.txt in the project root for license information.

using './main.bicep'

param environmentName = readEnvironmentVariable('AZURE_ENV_NAME', 'dev')
param location = readEnvironmentVariable('AZURE_LOCATION', 'westus')
param resourceGroupName = readEnvironmentVariable('AZURE_RESOURCE_GROUP', 'rg-${environmentName}')
param principalId = readEnvironmentVariable('AZURE_PRINCIPAL_ID', '')
