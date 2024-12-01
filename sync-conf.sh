#!/bin/bash

CLUSTER_NAME=$(terraform output -raw cluster_name)
if [[ -z "$CLUSTER_NAME" ]]; then
    echo "Failed to get CLUSTER_NAME from terraform output"
    exit
fi

RESOURCE_GROUP_NAME=$(terraform output -raw resource_group_name)
if [[ -z "$RESOURCE_GROUP_NAME" ]]; then
    echo "Failed to get RESOURCE_GROUP_NAME from terraform output"
    exit
fi

echo "Sync kubernetes configuration"
echo "Cluster name: $CLUSTER_NAME"
az aks get-credentials --resource-group $RESOURCE_GROUP_NAME --name $CLUSTER_NAME --overwrite-existing
kubectl config set-context $CLUSTER_NAME
