@description('Specifies the location for resources.')
param location string = 'eastus'

resource vnet 'Microsoft.Network/virtualNetworks@2022-09-01' = {
  name: 'TestVnetForAks'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '192.168.0.0/16'
      ]
    }
  }
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-09-01' = {
  parent: vnet
  name: 'Subnet1'
  properties: {
    addressPrefix: '192.168.1.0/24'
  }
}
