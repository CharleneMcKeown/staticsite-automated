// Params

@description('Enter your GitHub PAT')
@secure()
param token string

@description('In the format of: https://github.com/reponame')
param repositoryUrl string

@description('Which branch in the repo are you deploying from? e.g. main')
param branch string

@description('Where are the app artifacts located? e.g. public')
param appArtifactLocation string

@description('Enter a unique prefix - e.g. mecweb')
param namePrefix string

// Vars

var location = resourceGroup().location
var siteName = '${namePrefix}${uniqueString(resourceGroup().id)}'
var sku = 'Free'

// Create the Static Site 

resource staticSite 'Microsoft.Web/staticSites@2020-06-01' = {
  location: location
  name: siteName
  properties: {
    buildProperties:{
      appArtifactLocation: appArtifactLocation
    }
    repositoryUrl: repositoryUrl
    branch: branch
    repositoryToken: token
  }
  sku:{
    name: sku
  }
}

// Output
output siteName string = staticSite.name
output siteUrl string = staticSite.properties.defaultHostname
