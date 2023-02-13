@description('Specifies the name of the container app environment.')
param containerRegistryName string = 'cr${uniqueString(resourceGroup().id)}'

@description('Specifies the location for all resources.')
param location string = resourceGroup().location

@description('Number of conainer instances to create')
param instanceCount int = 3

@description('The EXISTING Azure DevOps agent pool name')
param azpPool string

@description('Azure DevOps ORG URI: https://dev.azure.com/{YourOrg}')
param azpUrl string

@secure()
@description('The personal access token with Agent Pools (read, manage) scope')
param azpToken string

module acr 'br/public:compute/container-registry:1.0.1' = {
  name: 'acr'
  params: {
    name: containerRegistryName
    location: location
    adminUserEnabled: true
  }
}

module buildAgentImage 'br/public:deployment-scripts/build-acr:1.0.1' = {
  name: 'buildAcrImage-linux-docker-agent'
  params: {
    initialScriptDelay: '0'
    AcrName: containerRegistryName
    location: location
    gitRepositoryUrl: 'https://github.com/jasperstone/containerized-build-agents.git'
    gitRepoDirectory: 'docker'
    imageName: 'dockeragent'
    imageTag: 'latest'
  }
  dependsOn: [
    acr
  ]
}

@description('This is the built-in AcrPull role. See https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#acrpull')
resource acrPullRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: '7f951dda-4ed3-4680-a7ca-43fe172d538d'
}

resource aciIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  name: 'id-acibuildagents'
  location: location
}

resource userAssignedIdentityRbac 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, aciIdentity.id, acrPullRoleDefinition.id)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: acrPullRoleDefinition.id
    principalId: aciIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource containerGroup 'Microsoft.ContainerInstance/containerGroups@2022-09-01' = [for i in range(0, instanceCount): {
  name: 'aci-buildagent-${padLeft(i, 2, '0')}'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${aciIdentity.id}': {}
    }
  }
  dependsOn: [
    buildAgentImage
  ]
  properties: {
    osType: 'Linux'
    imageRegistryCredentials: [
      {
        server: acr.outputs.loginServer
        identity: aciIdentity.id
      }
    ]
    containers: [
      {
        name: 'aci-buildagent-${padLeft(i, 2, '0')}'
        properties: {
          image: buildAgentImage.outputs.acrImage
          resources: {
            requests: {
              cpu: 1
              memoryInGB: 2
            }
          }
          environmentVariables: [
            {
              name: 'AZP_AGENT_NAME'
              value: 'aci-buildagent-${padLeft(i, 2, '0')}'
            }
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
              secureValue: azpToken
            }
          ]
        }
      }
    ]
  }
}]
