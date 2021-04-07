# Azure Static Web App and Logic Apps with Azure Bicep
This repo contains Azure Bicep files to create an Azure Static Web App and two Logic Apps to help with automation of adding new AAD backed members.

## What does it do? 

On a recent project, I was asked to explore Static Web Apps as an alternative to deploying a Hugo static site to Azure App Service. 

As part of this project, there is a requirement to automate the addition of new members to the website. Azure Static Web Apps integrate with Azure AD (and other auth providers), so I set about creating a process whereby:

1. A user can fill in a Microsoft Form to request access
1. That form submission will trigger a Logic App to send the details to a group email for approval
1. If approved, the Logic App will then trigger an Azure Pipeline
1. The pipeline will fetch the Form submitter's email address, and use that to add them to the web app using az cli
1. The pipeline will then trigger another Azure Logic App to email the user to welcome them to the website, along with the invitation URL

This initial workflow didn't take long at all - Static Sites are very easy to deploy, and Logic Apps with built in connectors meant that I got this all working in less than a day.

I thought it might be useful for others, so I created an [Azure Bicep](https://github.com/Azure/bicep) project to automate the deployment of:

- A static site
- Two Logic Apps (One to handle the Form submission, the other to handle the user invitation email)
- Three API connections to SaaS services: Office 365, Microsoft Forms and Azure DevOps

## Get started

To deploy this, simply follow these steps:

1. First of all, you need a repo with static contents. If you don't have one yet, you can fork this one: 
https://github.com/CharleneMcKeown/learningday

1. Install Azure Bicep by following this guide:
https://github.com/Azure/bicep/blob/main/docs/installing.md

1. Generate a GitHub Personal Access Token. You can follow this guide:
https://docs.github.com/en/github/authenticating-to-github/creating-a-personal-access-token

1. Clone this repo and change directory:
    ```
    git clone https://github.com/CharleneMcKeown/staticsite-automated.git
    cd staticsite-automated
    ```
1. Create an Azure Resource Group
    ```
    az group create -l westeurope -n staticsite-rg
    ```
1. Run the following command. You will be prompted for some parameters. Use ? to find out more information. 
    ```
    az deployment group create -f ./main.bicep -g staticsite-rg
    ```

    - **email**: Your Office 365 email address
    - **repo**: The repo where your static site contents are
    - **branch**: The branch you want to build your site from
    - **appArtifactLocation**: The location of your site files (usually public for a Hugo app)
    - **token**: GitHub Personal Access Token
    - **azureDevOpsAccountName**: Your Azure DevOps account name
    - **buildId**: The build Id for your Azure pipeline (if you haven't created it yet, just enter anything)

1. Once completed, you should find some outputs for:
    - siteUrl 
    - siteName
    - logicAppEndpoint

1. In this repo, you will find a file called add-user.yml. This is an Azure Pipeline file you can use to automate the process of adding a user. Update the variables with the outputs from the previous step.

    >Note: ToDo - Create the same workflow for GitHub. At this point, you should either add this Azure Pipeline to an existing repo you have, or push this repo to an Azure DevOps project.

1. Lastly, you'll need to log into the Azure portal and validate the api connections for O365, Forms and Azure DevOps. You can do this by clicking into the Logic App steps and logging in from there.

    >Note: For the Azure DevOps connection, the project name has been hard coded as **Hugo** in the logicapps.bicep file (line 141). You can manually update the file yourself, or change it in the Logic App. Similarly, the Forms ID is hardcoded - when you validate your own connection, you can choose your own Microsoft Form (once you have created one!)

## Closer Look

Coming soon: 

1. A deeper dive into the Logic Apps and how to generate a Logic App ARM template and convert it for use with Bicep. 
1. Static Web Apps - routes.json and Azure AD integration.
1. A nice architecture visual!




