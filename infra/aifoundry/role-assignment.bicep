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

@description('Principal ID for role assignment')
param principalId string

// AI Foundry instance with GPT-4o deployment
resource aiFoundry 'Microsoft.CognitiveServices/accounts@2025-04-01-preview' existing = {
  name: aiFoundryName
}

// Role Assignments for Logic App Identity to access AI Foundry
resource cognitiveServicesContributorRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '25fbc0a9-bd7c-42a3-aa1a-3b75d497ee68'
  scope: subscription()
}

resource roleAssignmentCognitiveServicesContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: aiFoundry
  name: guid(aiFoundryName, principalId, cognitiveServicesContributorRole.name)
  properties: {
    roleDefinitionId: cognitiveServicesContributorRole.id
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}

// Additional roles for AI Foundry access
resource azureAIAdministratorRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: 'b78c5d69-af96-48a3-bf8d-a8b4d589de94'
  scope: subscription()
}

resource roleAssignmentAzureAIAdministrator 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: aiFoundry
  name: guid(aiFoundryName, principalId, azureAIAdministratorRole.name)
  properties: {
    roleDefinitionId: azureAIAdministratorRole.id
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}

// Azure AI User role for accessing AI services
resource azureAIUserRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '53ca6127-db72-4b80-b1b0-d745d6d5456d'
  scope: subscription()
}

resource roleAssignmentAzureAIUser 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: aiFoundry
  name: guid(aiFoundryName, principalId, azureAIUserRole.name)
  properties: {
    roleDefinitionId: azureAIUserRole.id
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}

