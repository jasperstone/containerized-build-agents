@description('Name of the AKS cluster')
param aksClusterName string = 'aks-buildagents-${uniqueString(resourceGroup().id)}'

@description('Specifies the name of the container app environment.')
param containerRegistryName string = 'cr${uniqueString(resourceGroup().id)}'

@description('Specifies the location for all resources.')
param location string = resourceGroup().location

@description('The EXISTING Azure DevOps agent pool name')
param azpPool string

@description('Azure DevOps ORG URI: https://dev.azure.com/{YourOrg}')
param azpUrl string

@secure()
@description('The personal access token with Agent Pools (read, manage) scope')
param azpToken string

var deploymentYamlUrl = 'https://raw.githubusercontent.com/jasperstone/containerized-build-agents/main/templates/deployments/dockeragent.yaml'

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

module aks 'aks.bicep' = {
  name: aksClusterName
  params: {
    location: location
    aksClusterName: aksClusterName
    osType: 'Linux'
  }
}

// Discussion about how to assign AcrPull role to an AKS cluster
// https://github.com/Azure/bicep/discussions/3181
@description('This is the built-in AcrPull role. See https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#acrpull')
resource acrPullRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: '7f951dda-4ed3-4680-a7ca-43fe172d538d'
}

resource userAssignedIdentityRbac 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, aks.name, acrPullRoleDefinition.id)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: acrPullRoleDefinition.id
    principalId: aks.outputs.kubeletIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

module runAksDeploy 'br/public:deployment-scripts/aks-run-command:1.0.1' = {
  name: 'kubectlSecretAndDeployment'
  params: {
    initialScriptDelay: '0'
    aksName: aksClusterName
    commands: [
      'kubectl create configmap azdevops --from-literal=AZP_POOL=${azpPool} --from-literal=AZP_URL=${azpUrl} && kubectl create secret generic azdevops --from-literal=AZP_TOKEN=${azpToken}'
      'kubectl apply -f ${deploymentYamlUrl} && kubectl set image deployment/azdevops-deployment kubepodcreation=${buildAgentImage.outputs.acrImage}'
    ]
  }
  dependsOn: [
    buildAgentImage
    aks
  ]
}
