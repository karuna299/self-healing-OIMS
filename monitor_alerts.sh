#!/bin/bash

# Namespace and pod label for the webhook container
NAMESPACE="incident-mgmt"
POD_LABEL="app=ansible-webhook-receiver"

# Full path to your Ansible playbook on host
PLAYBOOK="/home/karuna/intern-elevate/self-healing-oims/ansible/restart_oims.yml"

echo "[INFO] Monitoring webhook receiver logs for HTTP 200 responses..."

# Get the webhook pod name dynamically
POD_NAME=$(kubectl get pod -n $NAMESPACE -l $POD_LABEL -o jsonpath="{.items[0].metadata.name}")

# Tail logs and trigger Ansible when "200" appears
kubectl logs -n $NAMESPACE -f $POD_NAME --since=1s | while IFS= read -r line
do
    if echo "$line" | grep -q " 200 "; then
        echo "[ALERT] HTTP 200 received! Running Ansible playbook..."
        ansible-playbook "$PLAYBOOK" -i localhost,
    fi
done