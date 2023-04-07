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

@description('Comma separated list of DNS nameservers: ["dns1", "dns2"]')
param nameservers array = []

@description('Url for the x509 root cert verifying the DevOps url')
param azpCertUrl string = ''

@description('Azure DevOps ORG URI: https://dev.azure.com/{YourOrg}')
param azpUrl string

@description('The EXISTING Azure DevOps agent pool name')
param azpPool string

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

module buildLinuxImage 'br/public:deployment-scripts/build-acr:2.0.1' = {
  name: 'buildLinuxImage'
  dependsOn: [ acr ]
  params: {
    initialScriptDelay: '0'
    AcrName: containerRegistryName
    location: location
    gitRepositoryUrl: 'https://github.com/jasperstone/containerized-build-agents.git'
    buildWorkingDirectory: 'docker/linuxagent'
    imageName: 'linuxagent'
    imageTag: 'latest'
  }
}

module buildLinuxContainerInstance 'aci.bicep' = {
  name: 'buildLinuxAci'
  dependsOn: [ buildLinuxImage ]
  params: {
    location: location
    containerRegistryName: containerRegistryName
    containerRegistryResourceGroup: resourceGroup().name
    subnetResourceGroup: subnetResourceGroup
    subnetName: subnetName
    nameservers: nameservers
    azpCertUrl: azpCertUrl
    osType: 'Linux'
    imageName: buildLinuxImage.outputs.acrImage
    azpPool: azpPool
    azpToken: azpToken
    azpUrl: azpUrl
    instanceCount: instanceCount
  }
}
