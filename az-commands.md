## Login
```
az login
```

Output:
```
a83e4e63-bd59-4a9a-83fe-6c0b18d16817 '2bcloud'

[Tenant and subscription selection]

No     Subscription name    Subscription ID                       Tenant
-----  -------------------  ------------------------------------  ---------------
[1] *  sandbox26/06/23      cac54a74-04fe-4cbf-91d0-dd16f5fd89bd  2bcloud Sandbox

The default is marked with an *; the default tenant is '2bcloud Sandbox' and subscription is 'sandbox26/06/23' (cac54a74-04fe-4cbf-91d0-dd16f5fd89bd).

Select a subscription and tenant (Type a number or Enter for no changes):

Tenant: 2bcloud Sandbox
Subscription: sandbox26/06/23 (cac54a74-04fe-4cbf-91d0-dd16f5fd89bd)
```

Login to specific domain
```
az login --tenant pictimeprod.onmicrosoft.com
```

## Account info
```
az account show
```

Personal account output
```
{
  "environmentName": "AzureCloud",
  "homeTenantId": "a83e4e63-bd59-4a9a-83fe-6c0b18d16817",
  "id": "428de810-7955-4499-841e-138ce4b3432a",
  "isDefault": true,
  "managedByTenants": [],
  "name": "Yuli - Free Trial Account",
  "state": "Enabled",
  "tenantDefaultDomain": "2bcloud.io",
  "tenantDisplayName": "2bcloud",
  "tenantId": "a83e4e63-bd59-4a9a-83fe-6c0b18d16817",
  "user": {
    "name": "Yuli@2bcloud.io",
    "type": "user"
  }
}
```

Staging account output
```
{
  "environmentName": "AzureCloud",
  "homeTenantId": "bd4f0481-b137-40f1-9e64-20cfd55fbf49",
  "id": "cac54a74-04fe-4cbf-91d0-dd16f5fd89bd",
  "isDefault": true,
  "managedByTenants": [
    {
      "tenantId": "a83e4e63-bd59-4a9a-83fe-6c0b18d16817"
    }
  ],
  "name": "sandbox26/06/23",
  "state": "Disabled",
  "tenantDefaultDomain": "2bcloudsandbox.onmicrosoft.com",
  "tenantDisplayName": "2bcloud Sandbox",
  "tenantId": "bd4f0481-b137-40f1-9e64-20cfd55fbf49",
  "user": {
    "name": "Yuli@2bcloud.io",
    "type": "user"
  }
}
```


## Makre sure to check that Container Service is enabled
```
az provider show --namespace "Microsoft.ContainerService" --query registrationState
```

Output:
```
NotRegistered
```

Enable
```
az feature register --name AKS-AzureKeyVaultSecretsProvider --namespace "Microsoft.ContainerService" 
```

Output:
```
Once the feature 'AKS-AzureKeyVaultSecretsProvider' is registered, invoking 'az provider register -n Microsoft.ContainerService' is required to get the change propagated
{
  "id": "/subscriptions/428de810-7955-4499-841e-138ce4b3432a/providers/Microsoft.Features/providers/Microsoft.ContainerService/features/AKS-AzureKeyVaultSecretsProvider",
  "name": "Microsoft.ContainerService/AKS-AzureKeyVaultSecretsProvider",
  "properties": {
    "state": "Registering"
  },
  "type": "Microsoft.Features/providers/features"
}
```

```
az provider register -n Microsoft.ContainerService
```

## Create resource group
```
export RESOURCE_GROUP_NAME="test-group1"
export REGION="westeurope"
export REGION="westus2"
az group create --name $RESOURCE_GROUP_NAME --location $REGION
```

```
az group delete --name $RESOURCE_GROUP_NAME -y
az group delete --name NetworkWatcherRG -y
```

Output:
```
{
  "id": "/subscriptions/428de810-7955-4499-841e-138ce4b3432a/resourceGroups/test-group1",
  "location": "westus2",
  "managedBy": null,
  "name": "test-group1",
  "properties": {
    "provisioningState": "Succeeded"
  },
  "tags": null,
  "type": "Microsoft.Resources/resourceGroups"
}
```

## Create cluster
```
export AKS_CLUSTER_NAME='cluster1'
az aks create --resource-group $RESOURCE_GROUP_NAME \
    --name $AKS_CLUSTER_NAME \
    --node-count 1 \
    --generate-ssh-keys
```

Output:
```
{
  "aadProfile": null,
  "addonProfiles": null,
  "agentPoolProfiles": [
    {
      "availabilityZones": null,
      "capacityReservationGroupId": null,
      "count": 1,
      "creationData": null,
      "currentOrchestratorVersion": "1.29.7",
      "enableAutoScaling": false,
      "enableEncryptionAtHost": false,
      "enableFips": false,
      "enableNodePublicIp": false,
      "enableUltraSsd": false,
      "gpuInstanceProfile": null,
      "hostGroupId": null,
      "kubeletConfig": null,
      "kubeletDiskType": "OS",
      "linuxOsConfig": null,
      "maxCount": null,
      "maxPods": 110,
      "minCount": null,
      "mode": "System",
      "name": "nodepool1",
      "networkProfile": null,
      "nodeImageVersion": "AKSUbuntu-2204gen2containerd-202407.22.0",
      "nodeLabels": null,
      "nodePublicIpPrefixId": null,
      "nodeTaints": null,
      "orchestratorVersion": "1.29",
      "osDiskSizeGb": 128,
      "osDiskType": "Managed",
      "osSku": "Ubuntu",
      "osType": "Linux",
      "podSubnetId": null,
      "powerState": {
        "code": "Running"
      },
      "provisioningState": "Succeeded",
      "proximityPlacementGroupId": null,
      "scaleDownMode": null,
      "scaleSetEvictionPolicy": null,
      "scaleSetPriority": null,
      "spotMaxPrice": null,
      "tags": null,
      "type": "VirtualMachineScaleSets",
      "upgradeSettings": {
        "drainTimeoutInMinutes": null,
        "maxSurge": "10%",
        "nodeSoakDurationInMinutes": null
      },
      "vmSize": "Standard_DS2_v2",
      "vnetSubnetId": null,
      "windowsProfile": null,
      "workloadRuntime": null
    }
  ],
  "apiServerAccessProfile": null,
  "autoScalerProfile": null,
  "autoUpgradeProfile": {
    "nodeOsUpgradeChannel": "NodeImage",
    "upgradeChannel": null
  },
  "azureMonitorProfile": null,
  "azurePortalFqdn": "cluster1-test-group1-428de8-s1q2997c.portal.hcp.westus2.azmk8s.io",
  "currentKubernetesVersion": "1.29.7",
  "disableLocalAccounts": false,
  "diskEncryptionSetId": null,
  "dnsPrefix": "cluster1-test-group1-428de8",
  "enablePodSecurityPolicy": null,
  "enableRbac": true,
  "extendedLocation": null,
  "fqdn": "cluster1-test-group1-428de8-s1q2997c.hcp.westus2.azmk8s.io",
  "fqdnSubdomain": null,
  "httpProxyConfig": null,
  "id": "/subscriptions/428de810-7955-4499-841e-138ce4b3432a/resourcegroups/test-group1/providers/Microsoft.ContainerService/managedClusters/cluster1",
  "identity": {
    "delegatedResources": null,
    "principalId": "c5f5d77c-6fe0-4b81-83b1-9c28eb019e02",
    "tenantId": "a83e4e63-bd59-4a9a-83fe-6c0b18d16817",
    "type": "SystemAssigned",
    "userAssignedIdentities": null
  },
  "identityProfile": {
    "kubeletidentity": {
      "clientId": "e8625394-2548-4082-bfe6-3de625cfeb3e",
      "objectId": "769de921-dc31-428e-8297-8522eea96335",
      "resourceId": "/subscriptions/428de810-7955-4499-841e-138ce4b3432a/resourcegroups/MC_test-group1_cluster1_westus2/providers/Microsoft.ManagedIdentity/userAssignedIdentities/cluster1-agentpool"
    }
  },
  "ingressProfile": null,
  "kubernetesVersion": "1.29",
  "linuxProfile": {
    "adminUsername": "azureuser",
    "ssh": {
      "publicKeys": [
        {
          "keyData": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCqnGrmfGb6vp7YmfcPMfs/sV8hyVdaXcDGVZwb08ipd1+KYQj59AlwJ5qUXZd/EcK8kJpxklMVazpd64RgQaGviGukd6iPrh+/OPIsFddLVoFuvtGxbM2TYHmm0KBpvOoXnfJ4yCIJ5LD7OTiJAtY2TdxEIjw7Pv0WrLukIUf1YikFR0F1HJFH9s1BSq5CxfOMD53iVUeaXJicexIcCP8RivoCf0G5jwOR0/OsUMLixfgrWWCQBEKRtqA7vg4ZEzuYlTWiTnx21KfuHFDAcbjqtSCwurcmXnRiHFx8rgEW9TExBqU+PM8jFBYqDXVI1HziPU9Lca/+sCDbPNKhPXw9"
        }
      ]
    }
  },
  "location": "westus2",
  "maxAgentPools": 100,
  "metricsProfile": {
    "costAnalysis": {
      "enabled": false
    }
  },
  "name": "cluster1",
  "networkProfile": {
    "dnsServiceIp": "10.0.0.10",
    "ipFamilies": [
      "IPv4"
    ],
    "loadBalancerProfile": {
      "allocatedOutboundPorts": null,
      "backendPoolType": "nodeIPConfiguration",
      "effectiveOutboundIPs": [
        {
          "id": "/subscriptions/428de810-7955-4499-841e-138ce4b3432a/resourceGroups/MC_test-group1_cluster1_westus2/providers/Microsoft.Network/publicIPAddresses/c2c1d9b4-151c-4a24-a7a3-2a62c014bac2",
          "resourceGroup": "MC_test-group1_cluster1_westus2"
        }
      ],
      "enableMultipleStandardLoadBalancers": null,
      "idleTimeoutInMinutes": null,
      "managedOutboundIPs": {
        "count": 1,
        "countIpv6": null
      },
      "outboundIPs": null,
      "outboundIpPrefixes": null
    },
    "loadBalancerSku": "standard",
    "natGatewayProfile": null,
    "networkDataplane": null,
    "networkMode": null,
    "networkPlugin": "kubenet",
    "networkPluginMode": null,
    "networkPolicy": "none",
    "outboundType": "loadBalancer",
    "podCidr": "10.244.0.0/16",
    "podCidrs": [
      "10.244.0.0/16"
    ],
    "serviceCidr": "10.0.0.0/16",
    "serviceCidrs": [
      "10.0.0.0/16"
    ]
  },
  "nodeResourceGroup": "MC_test-group1_cluster1_westus2",
  "oidcIssuerProfile": {
    "enabled": false,
    "issuerUrl": null
  },
  "podIdentityProfile": null,
  "powerState": {
    "code": "Running"
  },
  "privateFqdn": null,
  "privateLinkResources": null,
  "provisioningState": "Succeeded",
  "publicNetworkAccess": null,
  "resourceGroup": "test-group1",
  "resourceUid": "66bb16535cf145000116e00d",
  "securityProfile": {
    "azureKeyVaultKms": null,
    "defender": null,
    "imageCleaner": null,
    "workloadIdentity": null
  },
  "serviceMeshProfile": null,
  "servicePrincipalProfile": {
    "clientId": "msi",
    "secret": null
  },
  "sku": {
    "name": "Base",
    "tier": "Free"
  },
  "storageProfile": {
    "blobCsiDriver": null,
    "diskCsiDriver": {
      "enabled": true
    },
    "fileCsiDriver": {
      "enabled": true
    },
    "snapshotController": {
      "enabled": true
    }
  },
  "supportPlan": "KubernetesOfficial",
  "systemData": null,
  "tags": null,
  "type": "Microsoft.ContainerService/ManagedClusters",
  "upgradeSettings": null,
  "windowsProfile": null,
  "workloadAutoScalerProfile": {
    "keda": null,
    "verticalPodAutoscaler": null
  }
}
```

## Get cluster credentials
```
az aks get-credentials --resource-group $RESOURCE_GROUP_NAME --name $AKS_CLUSTER_NAME
```

## Install kubectl
```
brew install kubectl
```

## Copy kubeconfig
```
mv kubeconfig ~/.kube/config
```

## kubectl
```
kubectl cluster-info
kubectl get nodes
```

Output
```
Kubernetes control plane is running at https://myakscluster-0b2yfn5d.hcp.westus2.azmk8s.io:443
CoreDNS is running at https://myakscluster-0b2yfn5d.hcp.westus2.azmk8s.io:443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
Metrics-server is running at https://myakscluster-0b2yfn5d.hcp.westus2.azmk8s.io:443/api/v1/namespaces/kube-system/services/https:metrics-server:/proxy
```

## Nginx
```
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --port=80 --type=ClusterIP
kubectl port-forward service/nginx 8000:80
```

## Generated resources
```
generic-terraform % az resource list --resource-group MC_myResourceGroup_myAKSCluster_westus2 --output ```
```

| Name                                         | ResourceGroup                            | Location | Type                                               | Status |
|----------------------------------------------|------------------------------------------|----------|----------------------------------------------------|--------|
| 59e00f65-c254-4f96-8d73-0d7779a78c2a        | MC_myResourceGroup_myAKSCluster_westus2  | westus2  | Microsoft.Network/publicIPAddresses               |        |
| kubernetes                                  | mc_myresourcegroup_myakscluster_westus2  | westus2  | Microsoft.Network/loadBalancers                   |        |
| myAKSCluster-agentpool                      | MC_myResourceGroup_myAKSCluster_westus2  | westus2  | Microsoft.ManagedIdentity/userAssignedIdentities  |        |
| aks-agentpool-14693408-nsg                  | mc_myresourcegroup_myakscluster_westus2  | westus2  | Microsoft.Network/networkSecurityGroups           |        |
| aks-agentpool-14693408-routetable           | mc_myresourcegroup_myakscluster_westus2  | westus2  | Microsoft.Network/routeTables                     |        |
| aks-vnet-14693408                           | MC_myResourceGroup_myAKSCluster_westus2  | westus2  | Microsoft.Network/virtualNetworks                 |        |
| aks-default-35638291-vmss                   | MC_myResourceGroup_myAKSCluster_westus2  | westus2  | Microsoft.Compute/virtualMachineScaleSets         |        |
| kubernetes-a8e56b17727954842b8e820169c6de30 | mc_myresourcegroup_myakscluster_westus2  | westus2  | Microsoft.Network/publicIPAddresses               |        |

## Gen ssh key
```
cd ~/.ssh
ssh-keygen -t rsa -b 4096 -C "azurekey" -N "" -f azurekey
cd -
az sshkey create --name yuli-key --public-key @~/.ssh/azurekey.pub
```

## In bastion box
```
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
aksadmin@aks-default-40943090-vmss000000:~$ az account show
Please run 'az login' to setup account.
```
