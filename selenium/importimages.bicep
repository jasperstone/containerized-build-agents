param acrName string

var imageNames = [
  'docker.io/selenium/node-chrome'
  'docker.io/selenium/node-firefox'
  'docker.io/selenium/node-edge'
  'docker.io/selenium/hub'
  'docker.io/selenium/router'
  'docker.io/selenium/distributor'
  'docker.io/selenium/event-bus'
  'docker.io/selenium/sessions'
  'docker.io/selenium/session-queue'
]

module acrImport 'br/public:deployment-scripts/import-acr:3.0.1' = {
  name: 'importSeleniumImages'
  params: {
    acrName: acrName
    images: imageNames
  }
}
