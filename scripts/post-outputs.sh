#!/bin/bash
PROJECT=$1
OUTPUTS=$(terraform -chdir=stacks/$STACK_TYPE output -json)
az storage blob upload \
  --account-name sttfstateplatform \
  --container-name provisioner-outputs \
  --name "$PROJECT-$ENVIRONMENT.json" \
  --data "$OUTPUTS" \
  --overwrite