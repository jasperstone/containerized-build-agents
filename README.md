# Create Azure DevOps build agents running in containers

The Dockerfile and start.sh script are taken from the [Run a self-hosted agent in Docker](https://learn.microsoft.com/en-us/azure/devops/pipelines/agents/docker?view=azure-devops) instructions

## Agents running in AKS with Container Analytics
Scalable solution for your entire ADO org. Run your DEV builds here to build, test and create artifacts.
### Parameters
| Name | Type | Required | Description |
| :------------- | :----------: | :----------: | :------------- |
| aksClusterName | string | No | Name of your AKS cluster |
| containerRegistryName | string | No | Name of the Azure Container Registry |
| location | string | No | The resource location of the cluster |
| azpPool | string | Yes | The EXISTING Azure DevOps agent pool name |
| azpUrl | string | Yes | Azure DevOps ORG URI (https://dev.azure.com/{YourOrg}) |
| azpToken | string | Yes | The personal access token with Agent Pools (read, manage) scope |

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjasperstone%2Fcontainerized-build-agents%2Fmain%2Fazuredeploy.json)
[![Deploy to Azure](https://aka.ms/deploytoazuregovbutton)](https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjasperstone%2Fcontainerized-build-agents%2Fmain%2Fazuredeploy.json)
[![Visualize](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/visualizebutton.svg?sanitize=true)](http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2Fjasperstone%2Fcontainerized-build-agents%2Fmain%2Fazuredeploy.json)

---

## Agents running as Azure Container Instances
Simplest solution to get a few agents running. Not as scalable as AKS.  
Deploy these to try out build containers or in a partitioned environment like TEST or PROD to deploy artifacts.
### Parameters
| Name | Type | Required | Description |
| :------------- | :----------: | :----------: | :------------- |

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjasperstone%2Fcontainerized-build-agents%2Fmain%2Fazuredeploy.json)
[![Deploy to Azure](https://aka.ms/deploytoazuregovbutton)](https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjasperstone%2Fcontainerized-build-agents%2Fmain%2Fazuredeploy.json)
[![Visualize](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/visualizebutton.svg?sanitize=true)](http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2Fjasperstone%2Fcontainerized-build-agents%2Fmain%2Fazuredeploy.json)
