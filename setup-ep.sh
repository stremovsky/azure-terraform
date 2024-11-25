#!/bin/bash

TERRAFORM_OUTPUT=$(terraform output -json)
CLUSTER_NAME=$(echo "$TERRAFORM_OUTPUT" | jq -r '.cluster_name.value')
RESOURCE_GROUP_NAME=$(echo "$TERRAFORM_OUTPUT" | jq -r '.resource_group_name.value')
TENANT_ID=$(echo "$TERRAFORM_OUTPUT" | jq -r '.tenant_id.value')
KEYVAULT_NAME=$(echo "$TERRAFORM_OUTPUT" | jq -r '.ep_keyvault_name.value')
WORKLOAD_CLIENT_ID=$(echo "$TERRAFORM_OUTPUT" | jq -r '.ep_workload_identity_client_id.value')
WORKLOAD_IDENTITY_NAME=$(echo "$TERRAFORM_OUTPUT" | jq -r '.ep_workload_identity_name.value')

if [[ -z "$CLUSTER_NAME" || "$CLUSTER_NAME" == "null" ]]; then
    echo "Failed to get CLUSTER_NAME from terraform output"
    exit 1
fi
if [[ -z "$KEYVAULT_NAME" || "$KEYVAULT_NAME" == "null" ]]; then
    echo "Failed to get KEYVAULT_NAME from terraform output"
    exit 1
fi
if [[ -z "$RESOURCE_GROUP_NAME" || "$RESOURCE_GROUP_NAME" == "null" ]]; then
    echo "Failed to get RESOURCE_GROUP_NAME from terraform output"
    exit 1
fi
if [[ -z "$TENANT_ID" || "$TENANT_ID" == "null" ]]; then
    echo "Failed to get TENANT_ID from terraform output"
    exit 1
fi
if [[ -z "$WORKLOAD_CLIENT_ID" || "$WORKLOAD_CLIENT_ID" == "null" ]]; then
    echo "Failed to get WORKLOAD_CLIENT_ID from terraform output"
    exit 1
fi
if [[ -z "$WORKLOAD_IDENTITY_NAME" || "$WORKLOAD_IDENTITY_NAME" == "null" ]]; then
    echo "Failed to get WORKLOAD_IDENTITY_NAME from terraform output"
    exit 1
fi

#OLD_CONTEXT=$(kubectl config current-context)

echo "Sync kubernetes configuration"
echo "Cluster name: $CLUSTER_NAME"

az aks get-credentials --resource-group $RESOURCE_GROUP_NAME --name $CLUSTER_NAME
kubectl config set-context $CLUSTER_NAME

#kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.15.3/cert-manager.crds.yaml

if helm status ep --namespace ep &> /dev/null; then
    echo "Helm release 'ep' is already installed."
    helm upgrade ep ./base-chart \
        --namespace ep --create-namespace \
        --set tenantId=$TENANT_ID \
        --set keyvaultName=$KEYVAULT_NAME \
        --set workloadName=$WORKLOAD_IDENTITY_NAME \
        --set workloadClientId=$WORKLOAD_CLIENT_ID
else
    helm install ep ./base-chart \
        --namespace ep --create-namespace \
        --set tenantId=$TENANT_ID \
        --set keyvaultName=$KEYVAULT_NAME \
        --set workloadName=$WORKLOAD_IDENTITY_NAME \
        --set workloadClientId=$WORKLOAD_CLIENT_ID
fi
