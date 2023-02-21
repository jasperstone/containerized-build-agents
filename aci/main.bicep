@description('Specifies the name of the container app environment.')
param containerRegistryName string = 'cr${uniqueString(resourceGroup().id)}'

@description('Specifies the location for all resources.')
param location string = resourceGroup().location

@description('Number of conainer instances to create')
param instanceCount int = 3

@description('Subnet resource group name')
param subnetResourceGroup string = ''

@description('Existing subnet name (VNet/Subnet)')
param subnetName string = ''

@description('Comma separated list of DNS nameservers')
param nameservers array = []

@description('The EXISTING Azure DevOps agent pool name')
param azpPool string

@description('Azure DevOps ORG URI: https://dev.azure.com/{YourOrg}')
param azpUrl string

@description('Url for the p7b file containing the root cert for the DevOps url(optional)')
param azpCertUrl string = ''

@secure()
@description('The personal access token with Agent Pools (read, manage) scope')
param azpToken string

resource acr 'Microsoft.ContainerRegistry/registries@2021-09-01' = {
  name: containerRegistryName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
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

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-07-01' existing = {
  name: subnetName
  scope: resourceGroup(subnetResourceGroup)
}

resource containerGroup 'Microsoft.ContainerInstance/containerGroups@2021-09-01' = [for i in range(0, instanceCount): {
  name: 'aci-buildagent-${padLeft(i, 2, '0')}'
  location: location
  dependsOn: [
    buildAgentImage
  ]
  properties: {
    osType: 'Linux'
    imageRegistryCredentials: [
      {
        server: acr.properties.loginServer
        username: acr.listCredentials().username
        password: acr.listCredentials().passwords[0].value
      }
    ]
    subnetIds: empty(subnetName) ? null : [{ id: subnet.id }]
    dnsConfig: empty(nameservers) ? null : { nameServers: nameservers }
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
              name: 'AZP_CERT_URL'
              value: azpCertUrl
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
