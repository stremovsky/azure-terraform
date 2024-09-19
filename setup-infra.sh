#!/bin/bash

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

cd infra
mkdir -p charts
helm dependency update
cd ..

#kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.15.3/cert-manager.crds.yaml

helm install infra ./infra-chart \
  --namespace infra --create-namespace \
  --set serviceAccount.workloadClientId=$WORKLOAD_CLIENT_ID \
  --set serviceAccount.serviceAccountName=$WORKLOAD_IDENTITY_NAME

# helm delete infra --namespace infra
# kubectl delete -f https://github.com/cert-manager/cert-manager/releases/download/v1.15.3/cert-manager.crds.yaml
