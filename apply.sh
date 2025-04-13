#!/bin/bash

WORKSPACE=$(terraform workspace show)

if [ "$WORKSPACE" == "default" ]; then
  WORKSPACE="testing-eus1"
fi

echo "workspace: $WORKSPACE"

echo "running:"
echo "terraform apply -var-file=environments/$WORKSPACE/terraform.tfvars"
terraform apply -var-file=environments/$WORKSPACE/terraform.tfvars
