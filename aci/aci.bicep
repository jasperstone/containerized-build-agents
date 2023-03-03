@description('Resource group for the Azure container registry')
param containerRegistryResourceGroup string

@description('Specifies the name of the container app environment.')
param containerRegistryName string

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

@description('Image name')
param imageName string

@description('OS type of the image')
@allowed(['Linux', 'Windows'])
param osType string

@description('Url for the x509 root cert verifying the DevOps url')
param azpCertUrl string = ''

@description('Azure DevOps ORG URI: https://dev.azure.com/{YourOrg}')
param azpUrl string

@description('The EXISTING Azure DevOps agent pool name')
param azpPool string

@secure()
@description('The personal access token with Agent Pools (read, manage) scope')
param azpToken string

resource acr 'Microsoft.ContainerRegistry/registries@2021-09-01' existing = {
  name: containerRegistryName
  scope: resourceGroup(containerRegistryResourceGroup)
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-07-01' existing = {
  name: subnetName
  scope: resourceGroup(subnetResourceGroup)
}

var aciNames = [for i in range(0, instanceCount): toLower('aci-${osType}agent-${padLeft(i, 2, '0')}')]
resource containerGroup 'Microsoft.ContainerInstance/containerGroups@2021-09-01' = [for aciName in aciNames: {
  name: aciName
  location: location
  properties: {
    osType: osType
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
        name: aciName
        properties: {
          image: imageName
          resources: {
            requests: {
              cpu: 1
              memoryInGB: 2
            }
          }
          environmentVariables: [
            {
              name: 'AZP_AGENT_NAME'
              value: aciName
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
