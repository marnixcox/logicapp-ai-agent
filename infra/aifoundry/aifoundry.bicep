@description('The location used for all deployed resources')
param location string

@description('Tags that will be applied to all resources')
param tags object = {}

@description('Abbreviations for Azure resource naming')
param abbrs object

@description('Unique token for resource naming')
param resourceToken string

@description('Name of the environment that can be used as part of naming resource convention')
param environmentName string

@description('Name of AI Foundry instance')
param aiFoundryName string

@description('Name of AI Project within the AI Foundry instance')
param aiProjectName string = resourceToken

// AI Foundry instance with GPT-4o deployment
resource aiFoundry 'Microsoft.CognitiveServices/accounts@2025-04-01-preview' = {
  name: aiFoundryName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'S0'
  }
  kind: 'AIServices'
  properties: {
    allowProjectManagement: true 
    customSubDomainName: '${resourceToken}${environmentName}'
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: false
  }
}

// AI Project within the AI Foundry instance
resource aiProject 'Microsoft.CognitiveServices/accounts/projects@2025-04-01-preview' = {
  name: aiProjectName
  parent: aiFoundry
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {}
}

// GPT-4o deployment within the AI Foundry instance
resource modelDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01'= {
  parent: aiFoundry
  name: 'gpt-4o'
  tags: tags
  sku : {
    capacity: 1
    name: 'GlobalStandard'
  }
  properties: {
    model:{
      name: 'gpt-4o'
      format: 'OpenAI'
    }
  }
}

// Outputs for use by other modules
@description('AI Foundry Instance Name')
output aiFoundryName string = aiFoundry.name

@description('AI Foundry Endpoint URL')
output aiFoundryEndpoint string = aiFoundry.properties.endpoint

@description('AI Project Name')
output aiProjectName string = aiProject.name

@description('AI Project Endpoint URL')
output aiProjectEndpoint string = aiProject.properties.endpoints['AI Foundry API']
