#!/bin/bash

# Find directories containing *.tf files
directories=$(find . -type f -name "*.tf" -exec dirname {} \; | sort -u)

# Loop through each directory and run terraform fmt
for dir in $directories; do
  echo "Running 'terraform fmt' in $dir"
  (cd "$dir" && terraform fmt)
done

directories=$(find . -type f -name "*.tfvars" -exec dirname {} \; | sort -u)

# Loop through each directory and run terraform fmt
for dir in $directories; do
  echo "Running 'terraform fmt' in $dir"
  (cd "$dir" && terraform fmt)
done
