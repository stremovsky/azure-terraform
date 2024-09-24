#!/bin/bash

CLUSTER_NAME=$(terraform output -raw cluster_name)
if [[ -z "$CLUSTER_NAME" ]]; then
    echo "Failed to get CLUSTER_NAME from terraform output"
    exit
fi

KEYVAULT_NAME=$(terraform output -raw keyvault_name)
if [[ -z "$KEYVAULT_NAME" ]]; then
    echo "Failed to get KEYVAULT_NAME from terraform output"
    exit
fi

RESOURCE_GROUP_NAME=$(terraform output -raw resource_group_name)
if [[ -z "$RESOURCE_GROUP_NAME" ]]; then
    echo "Failed to get RESOURCE_GROUP_NAME from terraform output"
    exit
fi

TENANT_ID=$(terraform output -raw tenant_id)
if [[ -z "$TENANT_ID" ]]; then
    echo "Failed to get TENANT_ID from terraform output"
    exit
fi

WORKLOAD_CLIENT_ID=$(terraform output -raw workload_webapp_identity_client_id)
if [[ -z "$WORKLOAD_CLIENT_ID" ]]; then
    echo "Failed to get WORKLOAD_CLIENT_ID from terraform output"
    exit
fi

WORKLOAD_IDENTITY_NAME=$(terraform output -raw workload_identity_name)
if [[ -z "$WORKLOAD_IDENTITY_NAME" ]]; then
    echo "Failed to get WORKLOAD_IDENTITY_NAME from terraform output"
    exit
fi

cd infra-chart
mkdir -p charts
helm dependency update
cd ..

#OLD_CONTEXT=$(kubectl config current-context)

echo "Sync kubernetes configuration"
echo "Cluster name: $CLUSTER_NAME"

az aks get-credentials --resource-group $RESOURCE_GROUP_NAME --name $CLUSTER_NAME
kubectl config set-context $CLUSTER_NAME

#kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.15.3/cert-manager.crds.yaml

if helm status infra --namespace infra &> /dev/null; then
    echo "Helm release 'infra' is already installed."
    helm upgrade infra ./infra-chart \
        --namespace infra --create-namespace \
        --set tenantId=$TENANT_ID \
        --set keyvaultName=$KEYVAULT_NAME \
        --set workloadName=$WORKLOAD_IDENTITY_NAME \
        --set workloadClientId=$WORKLOAD_CLIENT_ID
else
    helm install infra ./infra-chart \
        --namespace infra --create-namespace \
        --set tenantId=$TENANT_ID \
        --set keyvaultName=$KEYVAULT_NAME \
        --set workloadName=$WORKLOAD_IDENTITY_NAME \
        --set workloadClientId=$WORKLOAD_CLIENT_ID
fi

# helm delete infra --namespace infra
# kubectl delete -f https://github.com/cert-manager/cert-manager/releases/download/v1.15.3/cert-manager.crds.yaml
