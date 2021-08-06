module staticapp './staticapp.bicep' = {
  name: 'staticAppDeploy'
  params: {
    token: token
    repositoryUrl: repo
    namePrefix: namePrefix
    branch: branch
    appArtifactLocation: appArtifactLocation
  }
}

// Deployment Scope
targetScope = 'resourceGroup'


@description('In the format of: https://github.com/account/reponame')
param repo string

@description('Which branch in the repo are you deploying from? e.g. main')
param branch string

@description('Where are the app artifacts located? e.g. public')
param appArtifactLocation string

@description('Enter your GitHub PAT')
@secure()
param token string

@description('Enter a unique prefix - e.g. mecweb')
param namePrefix string

// Outputs
output siteName string = staticapp.outputs.siteName
output siteUrl string = staticapp.outputs.siteUrl
