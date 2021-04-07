module logic './logicapps.bicep' = {
  name: 'logicAppsDeploy'
  params: {
    microsoftforms_displayName: email
    office365_displayName: email
    visualstudioteamservices_displayName: email
  }
}

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

// Parameters

@description('Enter your O365 email address')
param email string

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
output siteUrl string = staticapp.outputs.siteUrl
output endpoint string = logic.outputs.LogicAppEndPoint


