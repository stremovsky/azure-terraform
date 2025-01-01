#!/bin/bash

TERRAFORM_OUTPUT=$(terraform output -json)
CLUSTER_NAME=$(echo "$TERRAFORM_OUTPUT" | jq -r '.cluster_name.value')
RESOURCE_GROUP_NAME=$(echo "$TERRAFORM_OUTPUT" | jq -r '.resource_group_name.value')

if [[ -z "$CLUSTER_NAME" || "$CLUSTER_NAME" == "null" ]]; then
    echo "Failed to get CLUSTER_NAME from terraform output"
    exit 1
fi
if [[ -z "$RESOURCE_GROUP_NAME" || "$RESOURCE_GROUP_NAME" == "null" ]]; then
    echo "Failed to get RESOURCE_GROUP_NAME from terraform output"
    exit 1
fi

echo "Sync kubernetes configuration"

echo "Cluster name: $CLUSTER_NAME"

az aks get-credentials --resource-group $RESOURCE_GROUP_NAME --name $CLUSTER_NAME --overwrite-existing

kubectl config set-context $CLUSTER_NAME

helm uninstall ep --namespace ep || true
