param location string = resourceGroup().location

@description('Existing subnet resource group')
param subnetRg string

@description('Existing subnet name (VNet/Subnet)')
param subnetName string

@description('Existing managed identity name for cluster')
param managedIdentityname string

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-09-01' existing = {
  name: subnetName
  scope: resourceGroup(subnetRg)
}

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: managedIdentityname
}

resource aks 'Microsoft.ContainerService/managedClusters@2021-09-01' = {
  location: location
  name: 'selenium'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    dnsPrefix: 'selenium-dns'
    nodeResourceGroup: 'MC_${resourceGroup().name}'
    agentPoolProfiles: [
      {
        name: 'default'
        count: 1
        vmSize: 'Standard_B4ms'
        mode: 'System'
        type: 'VirtualMachineScaleSets'
        vnetSubnetID: subnet.id
      }
    ]
    networkProfile: {
      loadBalancerSku: 'basic'
      networkPlugin: 'azure'
    }
  }
}

module runCmd 'br/public:deployment-scripts/aks-run-command:1.0.3' = {
  name: 'helmInstallSeleniumGrid'
  params: {
    aksName: aks.name
    location: location
    commands: [
      'helm repo add docker-selenium https://www.selenium.dev/docker-selenium; helm repo update; helm upgrade --install selenium-grid docker-selenium/selenium-grid --set isolateComponents=true'
    ]
  }
}
