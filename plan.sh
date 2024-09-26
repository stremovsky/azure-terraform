#!/bin/bash

WORKSPACE=$(terraform workspace show)

if [ "$WORKSPACE" == "default" ]; then
  WORKSPACE="dev-eus1"
fi

echo "workspace: $WORKSPACE"

terraform plan -var-file=environments/$WORKSPACE/terraform.tfvars