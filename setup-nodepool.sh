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

az aks nodepool add --cluster-name $CLUSTER_NAME \
  --resource-group $RESOURCE_GROUP_NAME --name m0d0 \
  --node-osdisk-type Ephemeral --node-osdisk-size 440 \
  --enable-cluster-autoscaler --min-count 1 --max-count 10 \
  --node-vm-size Standard_D8ads_v6 --labels simple=true windows=true \  
  --os-type Windows --os-sku Windows2022 --aks-custom-headers UseWindowsGen2VM=true