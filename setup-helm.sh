#!/bin/bash

WORKLOAD_CLIENT_ID=$(terraform output -raw workload_identity_client_id)
if [[ -z "$WORKLOAD_CLIENT_ID" ]]; then
    echo "Failed to get WORKLOAD_CLIENT_ID from terraform output"
    exit
fi

WORKLOAD_IDENTITY_NAME=$(terraform output -raw workload_identity_name)
if [[ -z "$WORKLOAD_IDENTITY_NAME" ]]; then
    echo "Failed to get WORKLOAD_IDENTITY_NAME from terraform output"
    exit
fi

helm install cert-manager jetstack/cert-manager --create-namespace --namespace infra --version v1.15.3 --set crds.enabled=true --wait
helm install ingress-nginx ingress-nginx/nginx-ingress --namespace infra --create-namespace \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"="/healthz" \
  --set controller.service.externalTrafficPolicy=Local \
  --set controller.allowSnippetAnnotations=true

kubectl create serviceaccount my-service-account --dry-run=client -o yaml | kubectl annotate --overwrite -f - azure.workload.identity/client-id=$WORKLOAD_CLIENT_ID -o yaml | kubectl apply -f -

# Define the ClusterIssuer YAML as a variable
CLUSTER_ISSUER=$(cat <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-prod-private-key
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
)

# Pipe the variable to kubectl
echo "$CLUSTER_ISSUER" | kubectl apply -f -