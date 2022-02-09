@secure()
param sshpub string
param name string
param adminusername string
param appgwid string
param servicecidr string
param podcidr string
param dockercidr string
param dnsservice string
param subnetid string
var location = resourceGroup().location

resource aks 'Microsoft.ContainerService/managedClusters@2021-10-01' = {
  name: name
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    dnsPrefix: 'akspoc'
    agentPoolProfiles: [
      {
        name: 'agentpool'
        osDiskSizeGB: 0
        count: 1
        vmSize: 'Standard_D2s_v3'
        osType: 'Linux'
        mode: 'System'
        vnetSubnetID: subnetid
      }
    ]
    linuxProfile: {
      adminUsername: adminusername
      ssh: {
        publicKeys: [
          {
            keyData: sshpub
          }
        ]
      }
    }
    addonProfiles: {
      ingressApplicationGateway: {
        enabled: true
        config: {
          applicationGatewayId: appgwid
        }
      }
    }
    enableRBAC: true
    networkProfile: {
      networkPlugin: 'azure'
      networkPolicy: 'azure'
      podCidr: podcidr
      serviceCidr: servicecidr
      dockerBridgeCidr: dockercidr
      dnsServiceIP: dnsservice
    }
  }
}

resource contrib 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid('aks-roleassignment-agic')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
    principalId: aks.properties.addonProfiles.ingressApplicationGateway.identity.objectId
    principalType: 'ServicePrincipal'
  }
  scope: resourceGroup()
}
