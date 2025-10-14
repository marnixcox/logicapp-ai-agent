@description('The location used for all deployed resources')
param location string = resourceGroup().location

@description('Tags that will be applied to all resources')
param tags object = {}

@description('Name of the environment that can be used as part of naming resource convention')
param environmentName string

@description('Unique token for resource naming')
param resourceToken string = toLower(uniqueString(subscription().id, environmentName, location))

var abbrs = loadJsonContent('./abbreviations.json')

// Monitor application with Azure Monitor
module monitoring './monitoring.bicep' = {
  name: '${deployment().name}-monitoring'
  params: {
    location: location
    tags: tags
    abbrs: abbrs
    environmentName: environmentName
    resourceToken: resourceToken
  }
}

// AI Foundry instance with GPT-4o deployment
module aiFoundry './aifoundry/aifoundry.bicep' = {
  name: '${deployment().name}-aifoundry'
  params: {
    location: location
    tags: tags
    abbrs: abbrs
    environmentName: environmentName
    resourceToken: resourceToken
    aiFoundryName: '${abbrs.aiFoundryAccounts}-${resourceToken}-${environmentName}'
  }
}

// Role Assignment to allow Logic App access to AI Foundry
module aifoundryRoleAssignment './aifoundry/role-assignment.bicep' = {
  name: '${deployment().name}-aifoundry-roleassignment'
  params: {
    location: location
    tags: tags
    abbrs: abbrs
    environmentName: environmentName
    resourceToken: resourceToken
    aiFoundryName: aiFoundry.outputs.aiFoundryName
    principalId: workflows.outputs.logicAppPrincipalId
  }
}

// Storage for Azure Functions and Logic Apps 
module storage './storage/storage.bicep' = {
  name: '${deployment().name}-storage'
  params: {
    location: location
    tags: tags
    abbrs: abbrs
    environmentName: environmentName
    resourceToken: resourceToken
    logAnalyticsWorkspaceResourceId: monitoring.outputs.logAnalyticsWorkspaceResourceId
    logicAppIdentity: logicIdentity.outputs.principalId
  }
}

// User Assigned Identity for Logic App
module logicIdentity 'br/public:avm/res/managed-identity/user-assigned-identity:0.2.1' = {
  name: '${deployment().name}-logicidentity'
  params: {
    name: '${abbrs.managedIdentityUserAssignedIdentities}${abbrs.logicWorkflows}${resourceToken}-${environmentName}'
    location: location
  }
}

// Logic App Standard Plan
module logicappplan './logicapp/plan.bicep' = {
  name: '${deployment().name}-logicappplan'
  params: {
    location: location
    tags: tags
    abbrs: abbrs
    environmentName: environmentName
    resourceToken: resourceToken
    logAnalyticsWorkspaceResourceId: monitoring.outputs.logAnalyticsWorkspaceResourceId
  }
}

// Logic App Standard Workflows with shared plan
module workflows './logicapp/workflows.bicep' = {
  name: '${deployment().name}-workflows'
  params: {
    location: location
    tags: tags
    abbrs: abbrs
    environmentName: environmentName
    resourceToken: resourceToken
    applicationInsightsConnectionString: monitoring.outputs.applicationInsightsConnectionString
    appPlanName: logicappplan.outputs.logicAppPlanName
    storageAccountName: storage.outputs.storageAccountName
    logicAppIdentity: logicIdentity.outputs.resourceId
    appsettings: {
      AI_FOUNDRY_NAME: aiFoundry.outputs.aiFoundryName
      AI_FOUNDRY_ENDPOINT: aiFoundry.outputs.aiFoundryEndpoint
      AI_PROJECT_NAME: aiFoundry.outputs.aiProjectName
      AI_PROJECT_ENDPOINT: aiFoundry.outputs.aiProjectEndpoint
    }
  }
}
