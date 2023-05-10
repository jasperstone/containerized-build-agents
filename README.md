# Create Azure DevOps build agents running in containers

The Dockerfile and start.sh script are taken from the [Run a self-hosted agent in Docker](https://learn.microsoft.com/en-us/azure/devops/pipelines/agents/docker?view=azure-devops) instructions

## Agents running as Azure Container Instances
Simplest solution to get a few agents running. Not as scalable as AKS.  
Deploy these to try out build containers or in a partitioned environment like TEST or PROD to deploy artifacts.
### Parameters
Parameter name | Required | Description
-------------- | -------- | -----------
containerRegistryName | No       | Specifies the name of the container app environment.
location       | No       | Specifies the location for all resources.
instanceCount  | No       | Number of conainer instances to create
subnetResourceGroup | No       | Subnet resource group name
subnetName     | No       | Existing subnet name (VNet/Subnet)
nameservers    | No       | Comma separated list of DNS nameservers: ["dns1", "dns2"]
rootCertUrl    | No       | Url for PEM formatted x509 root cert bundle to import
azpUrl         | Yes      | Azure DevOps ORG URI: https://dev.azure.com/{YourOrg}
azpPool        | Yes      | The EXISTING Azure DevOps agent pool name
azpToken       | Yes      | The personal access token with Agent Pools (read, manage) scope

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjasperstone%2Fcontainerized-build-agents%2Fmain%2Faci%2Fazuredeploy.json)
[![Deploy to Azure](https://aka.ms/deploytoazuregovbutton)](https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjasperstone%2Fcontainerized-build-agents%2Fmain%2Faci%2Fazuredeploy.json)
[![Visualize](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/visualizebutton.svg?sanitize=true)](http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2Fjasperstone%2Fcontainerized-build-agents%2Fmain%2Faci%2Fazuredeploy.json)

---

## Agents running in AKS with Container Analytics
Scalable solution for your entire ADO org. Run your DEV builds here to build, test and create artifacts.
### Parameters
Parameter name | Required | Description
-------------- | -------- | -----------
aksClusterName | No       | Name of the AKS cluster
containerRegistryName | No       | Specifies the name of the container app environment.
location       | No       | Specifies the location for all resources.
azpPool        | Yes      | The EXISTING Azure DevOps agent pool name
azpUrl         | Yes      | Azure DevOps ORG URI: https://dev.azure.com/{YourOrg}
azpToken       | Yes      | The personal access token with Agent Pools (read, manage) scope

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjasperstone%2Fcontainerized-build-agents%2Fmain%2Faks%2Fazuredeploy.json)
[![Deploy to Azure](https://aka.ms/deploytoazuregovbutton)](https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjasperstone%2Fcontainerized-build-agents%2Fmain%2Faks%2Fazuredeploy.json)
[![Visualize](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/visualizebutton.svg?sanitize=true)](http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2Fjasperstone%2Fcontainerized-build-agents%2Fmain%2Faks%2Fazuredeploy.json)
