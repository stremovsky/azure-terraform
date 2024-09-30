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

az aks get-credentials --resource-group $RESOURCE_GROUP_NAME --name $CLUSTER_NAME
kubectl config set-context $CLUSTER_NAME

echo
read -p "Enter API key (uuid string): " APIKEY
read -p "Enter APP key: " APPKEY

kubectl create secret generic datadog-secret --from-literal api-key=$APIKEY --from-literal app-key=$APPKEY

helm repo add datadog https://helm.datadoghq.com
helm repo update
helm upgrade "datadog" -f ./datadog_azure.yaml --set datadog.clusterName="$CLUSTER_NAME" datadog/datadog

if helm status datadog --namespace default &> /dev/null; then
    echo "Helm release 'datadog' is already installed."
    helm upgrade "datadog" -f ./datadog_azure.yaml --set datadog.clusterName="$CLUSTER_NAME" datadog/datadog
else
    helm install "datadog" -f ./datadog_azure.yaml --set datadog.clusterName="$CLUSTER_NAME" datadog/datadog
fi
