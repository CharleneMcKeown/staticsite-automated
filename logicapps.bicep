var sendEmailLogicAppName = '${namePrefix}send${uniqueString(resourceGroup().id)}'
var triggerApprovalLogicAppName = '${namePrefix}trigger${uniqueString(resourceGroup().id)}'

param namePrefix string = 'webmec'
var location = resourceGroup().location

param office365_name string = 'office365'
// For the O365 Connector, enter an email
param office365_displayName string

param microsoftforms_name string = 'microsoftforms'
// For the Forms Connector, enter an email
param microsoftforms_displayName string

@description('Your Azure DevOps Account Name')
param azureDevOpsAccount string
@description('Your Build Id')
param buildId string


param visualstudioteamservices_name string = 'visualstudioteamservices'
param visualstudioteamservices_displayName string

resource sendEmail_LogicApp 'Microsoft.Logic/workflows@2016-06-01' = {
  name: sendEmailLogicAppName
  location: location
  properties: {
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        '$connections': {
          defaultValue: {}
          type: 'Object'
        }
      }
      triggers: {
        manual: {
          type: 'Request'
          kind: 'Http'
          inputs: {
            schema: {
              properties: {
                email: {
                  type: 'string'
                }
                invitationUrl: {
                  type: 'string'
                }
              }
              type: 'object'
            }
          }
        }
      }
      actions: {
        'Send_an_email_(V2)': {
          runAfter: {}
          type: 'ApiConnection'
          inputs: {
            body: {
              Body: '<p>Your request to become a champ has been accepted. Click on the below URL to authenticate to the site with your microsoft email. <br>\n<br>\n@{triggerBody()?[\'invitationUrl\']}</p>'
              Subject: 'Welcome to Champs!'
              To: '@triggerBody()?[\'email\']'
            }
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'office365\'][\'connectionId\']'
              }
            }
            method: 'post'
            path: '/v2/Mail'
          }
        }
      }
      outputs: {}
    }
    parameters: {
      '$connections': {
        value: {
          office365: {
            id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/office365'
            connectionId: office365_name_resource.id
            connectionName: office365_name
          }
        }
      }
    }
  }
}

resource triggerApproval_LogicApp 'Microsoft.Logic/workflows@2016-06-01' = {
  name: triggerApprovalLogicAppName
  location: location
  properties: {
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        '$connections': {
          defaultValue: {}
          type: 'Object'
        }
      }
      triggers: {
        When_a_new_response_is_submitted: {
          splitOn: '@triggerBody()?[\'value\']'
          type: 'ApiConnectionWebhook'
          inputs: {
            body: {
              eventType: 'responseAdded'
              notificationUrl: '@{listCallbackUrl()}'
              source: 'ms-connector'
            }
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'microsoftforms\'][\'connectionId\']'
              }
            }
            path: '/formapi/api/forms/@{encodeURIComponent(\'v4j5cvGGr0GRqy180BHbR3z9iPkn9OhAir21N6avl2RUQlkzM0U3NUhYUUNEQklDQzRUTzRFUTc0VS4u\')}/webhooks'
          }
        }
      }
      actions: {
        Condition: {
          actions: {
            Queue_a_new_build: {
              runAfter: {}
              type: 'ApiConnection'
              inputs: {
                body: {
                  parameters: '{"userEmail": "@{body(\'Get_response_details\')?[\'responder\']}" }'
                  sourceBranch: 'main'
                }
                host: {
                  connection: {
                    name: '@parameters(\'$connections\')[\'visualstudioteamservices\'][\'connectionId\']'
                  }
                }
                method: 'post'
                path: '/@{encodeURIComponent(\'Hugo\')}/_apis/build/builds'
                queries: {
                  account: azureDevOpsAccount
                  buildDefId: buildId
                }
              }
            }
          }
          runAfter: {
            Send_approval_email: [
              'Succeeded'
            ]
          }
          expression: {
            and: [
              {
                contains: [
                  '@body(\'Send_approval_email\')?[\'SelectedOption\']'
                  'Approve'
                ]
              }
            ]
          }
          type: 'If'
        }
        Get_response_details: {
          runAfter: {}
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'microsoftforms\'][\'connectionId\']'
              }
            }
            method: 'get'
            path: '/formapi/api/forms(\'@{encodeURIComponent(\'v4j5cvGGr0GRqy180BHbR3z9iPkn9OhAir21N6avl2RUQlkzM0U3NUhYUUNEQklDQzRUTzRFUTc0VS4u\')}\')/responses'
            queries: {
              response_id: '@triggerBody()?[\'resourceData\']?[\'responseId\']'
            }
          }
        }
        Send_approval_email: {
          runAfter: {
            Get_response_details: [
              'Succeeded'
            ]
          }
          type: 'ApiConnectionWebhook'
          inputs: {
            body: {
              Message: {
                HideHTMLMessage: false
                Importance: 'Normal'
                Options: 'Approve, Reject'
                ShowHTMLConfirmationDialog: false
                Subject: 'Approval Request'
                To: 'mmckeown@microsoft.com'
              }
              NotificationUrl: '@{listCallbackUrl()}'
            }
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'office365\'][\'connectionId\']'
              }
            }
            path: '/approvalmail/$subscriptions'
          }
        }
      }
      outputs: {}
    }
    parameters: {
      '$connections': {
        value: {
          microsoftforms: {
            id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/microsoftforms'
            connectionId: microsoftforms_name_resource.id
            connectionName: microsoftforms_name
          }
          office365: {
            id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/office365'
            connectionId: office365_name_resource.id
            connectionName: office365_name
          }
          visualstudioteamservices: {
            id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/visualstudioteamservices'
            connectionId: visualstudioteamservices_name_resource.id
            connectionName: visualstudioteamservices_name
          }
        }
      }
    }
  }
}

resource office365_name_resource 'Microsoft.Web/connections@2016-06-01' = {
  location: location
  name: office365_name
  properties: {
    api: {
      id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/office365'
    }
    displayName: office365_displayName
  }
}

resource microsoftforms_name_resource 'Microsoft.Web/connections@2016-06-01' = {
  location: location
  name: microsoftforms_name
  properties: {
    api: {
      id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/microsoftforms'
    }
    displayName: microsoftforms_displayName
  }
}

resource visualstudioteamservices_name_resource 'Microsoft.Web/connections@2016-06-01' = {
  location: location
  name: visualstudioteamservices_name
  properties: {
    api: {
      id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/visualstudioteamservices'
    }
    displayName: visualstudioteamservices_displayName
  }
}

output LogicAppEndPoint string = triggerApproval_LogicApp.properties.accessEndpoint
