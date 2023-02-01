@description('Specifies the name of the container app.')
param containerAppName string = 'app-${uniqueString(resourceGroup().id)}'

@description('Specifies the name of the container app environment.')
param containerAppEnvName string = 'env-${uniqueString(resourceGroup().id)}'

@description('Specifies the name of the log analytics workspace.')
param containerAppLogAnalyticsName string = 'containerapp-log-${uniqueString(resourceGroup().id)}'

@description('Specifies the name of the container app environment.')
param containerRegistryName string = 'cr${uniqueString(resourceGroup().id)}'

@description('Specifies the location for all resources.')
param location string = resourceGroup().location

@description('Number of replicas to deploy')
@minValue(0)
@maxValue(25)
param numReplicas int = 3

param utcNowString string = utcNow()

@description('The EXISTING Azure DevOps agent pool name')
param azpPool string

@description('The url for your Azure DevOps ORG')
param azpUrl string = 'https://dev.azure.com/{YourOrg}'

@secure()
@description('The personal access token with Agent Pools (read, manage) scope')
param azpToken string

var acrPullRole = resourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
var contributorRole = resourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: containerAppLogAnalyticsName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
}

module acr 'containerRegistry.bicep' = {
  name: 'acr'
  params: {
    location: location
    containerRegistryName: containerRegistryName
  }
}

resource containerAppEnv 'Microsoft.App/managedEnvironments@2022-06-01-preview' = {
  name: containerAppEnvName
  location: location
  sku: {
    name: 'Consumption'
  }
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalytics.properties.customerId
        sharedKey: logAnalytics.listKeys().primarySharedKey
      }
    }
  }
}

resource uai 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  name: 'id-${containerAppName}'
  location: location
}

resource uaiBuildAndPushImage 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  name: 'id-buildAndPushImage'
  location: location
}

@description('This allows the managed identity of the container app to access the registry, note scope is applied to the wider ResourceGroup not the ACR')
resource uaiRbac 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, uai.id, acrPullRole)
  properties: {
    roleDefinitionId: acrPullRole
    principalId: uai.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

@description('This allows the managed identity of the deployment script to access the registry, note scope is applied to the wider ResourceGroup not the ACR')
resource uaiRbacBuildAndPushImage 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, uaiBuildAndPushImage.id, contributorRole)
  properties: {
    roleDefinitionId: contributorRole
    principalId: uaiBuildAndPushImage.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource buildAndPushImage 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'buildAndPushImage'
  location: location
  kind: 'AzureCLI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${uaiBuildAndPushImage.id}': {}
    }
  }
  properties: {
    forceUpdateTag: utcNowString
    azCliVersion: '2.40.0'
    environmentVariables: [
      {
        name: 'acrName'
        value: acr.outputs.loginServer
      }
      {
        name: 'rgName'
        value: resourceGroup().name
      }
    ]
    primaryScriptUri: 'https://raw.githubusercontent.com/jasperstone/containerized-build-agents/main/buildAndPushDockerAgent.sh'
    timeout: 'PT15M'
    cleanupPreference: 'OnSuccess'
    retentionInterval: 'P1D'
  }
}

resource containerApp 'Microsoft.App/containerApps@2022-06-01-preview' = {
  name: containerAppName
  location: location
  dependsOn: [
    buildAndPushImage
  ]
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${uai.id}': {}
    }
  }
  properties: {
    managedEnvironmentId: containerAppEnv.id
    configuration: {
      registries: [
        {
          identity: uai.id
          server: acr.outputs.loginServer
        }
      ]
      secrets: [
        {
          name: 'azptoken'
          value: azpToken
        }
      ]
    }
    template: {
      revisionSuffix: 'firstrevision'
      containers: [
        {
          name: containerAppName
          image: '${acr.outputs.loginServer}/dockeragent:latest'
          resources: {
            cpu: json('.25')
            memory: '.5Gi'
          }
          env: [
            {
              name: 'AZP_POOL'
              value: azpPool
            }
            {
              name: 'AZP_URL'
              value: azpUrl
            }
            {
              name: 'AZP_TOKEN'
              secretRef: 'azptoken'
            }
          ]
        }
      ]
      scale: {
        minReplicas: numReplicas
        maxReplicas: numReplicas
      }
    }
  }
}
