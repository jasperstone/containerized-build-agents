curl -O https://raw.githubusercontent.com/jasperstone/containerized-build-agents/main/docker/Dockerfile
curl -O https://raw.githubusercontent.com/jasperstone/containerized-build-agents/main/docker/start.sh
az acr build -t dockeragent:latest -r $acrName -g $rgName .