#!/bin/bash

TERRAFORM_OUTPUT=$(terraform output -json)
CLUSTER_NAME=$(echo "$TERRAFORM_OUTPUT" | jq -r '.cluster_name.value')
RESOURCE_GROUP_NAME=$(echo "$TERRAFORM_OUTPUT" | jq -r '.resource_group_name.value')
LB_PUBLIC_IP=$(echo "$TERRAFORM_OUTPUT" | jq -r '.lb_public_ip.value')

if [[ -z "$CLUSTER_NAME" || "$CLUSTER_NAME" == "null" ]]; then
    echo "Failed to get CLUSTER_NAME from terraform output"
    exit 1
fi
if [[ -z "$RESOURCE_GROUP_NAME" || "$RESOURCE_GROUP_NAME" == "null" ]]; then
    echo "Failed to get RESOURCE_GROUP_NAME from terraform output"
    exit 1
fi
if [[ -z "$LB_PUBLIC_IP" || "$LB_PUBLIC_IP" == "null" ]]; then
    echo "Failed to get LB_PUBLIC_IP from terraform output"
    exit
fi

cd infra-chart
mkdir -p charts
helm dependency update
cd ..

#OLD_CONTEXT=$(kubectl config current-context)

echo "Sync kubernetes configuration"
echo "Cluster name: $CLUSTER_NAME"

az aks get-credentials --resource-group $RESOURCE_GROUP_NAME --name $CLUSTER_NAME --overwrite-existing
kubectl config set-context $CLUSTER_NAME

#kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.15.3/cert-manager.crds.yaml

if helm status infra --namespace infra &> /dev/null; then
    echo "Helm release 'infra' is already installed."
    helm upgrade infra ./infra-chart \
        --namespace infra --create-namespace \
        --set ingress-nginx.controller.service.loadBalancerIP=$LB_PUBLIC_IP
else
    helm install infra ./infra-chart \
        --namespace infra --create-namespace \
        --set ingress-nginx.controller.service.loadBalancerIP=$LB_PUBLIC_IP
fi

# helm delete infra --namespace infra
# kubectl delete -f https://github.com/cert-manager/cert-manager/releases/download/v1.15.3/cert-manager.crds.yaml
