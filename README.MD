# OIMS – Open Incident Management System

OIMS (Open Incident Management System) is a Python Flask-based Incident Management application that lets users create, assign, track, and resolve incidents. It integrates monitoring (Prometheus), alert routing (AlertManager), and automation (Ansible). A lightweight Flask webhook receives alerts and — via an external monitor script — triggers Ansible playbooks to perform recovery actions.

---

## Tech Stack

- Python 3.12  
- Flask (Incident app + webhook receiver)  
- SQLite (local app DB for demo)  
- Docker  
- Kubernetes (Minikube for local testing)  
- Prometheus (monitoring)  
- AlertManager (alert routing → webhook)  
- Ansible (automation / playbooks)  
- SMTP (email notifications)

---

## What the system does (high level)

- **Incident App (core)** — A Flask web app where users can:
  - Register / Login
  - Create incidents
  - Assign incidents to users
  - Resolve incidents
  - Receive email notifications when incidents are **created**, **assigned**, and **resolved**

- **Monitoring & Alerting**
  - Prometheus scrapes metrics from the Incident App to detect unhealthy behavior.
  - If Prometheus rules fire, AlertManager sends the alert payload to the Flask Webhook Receiver.

- **Webhook Receiver + Automation**
  - The webhook receives the HTTP POST and responds `200 OK`.
  - A host-side script (`monitor_alerts.sh`) monitors the webhook pod logs and runs an Ansible playbook when an alert is detected.
  - Keeping `kubectl` out of the webhook container makes it lightweight; Ansible and kubectl actions run from the host.

---

## Architecture (text diagram)

```
[Incident App (Flask)] <--emails-- SMTP
        |
     metrics
        v
   [Prometheus] --alert--> [AlertManager] --webhook--> [Flask Webhook Receiver (pod)]
                                                             |
                                                         logs  (monitored)
                                                             v
                                                      [monitor_alerts.sh on host]
                                                             |
                                                   ansible-playbook restart_oims.yml
                                                             |
                                                   (performs restart/scale actions)
                                                             |
                                                     [Kubernetes Deployment]
```

---

## Important notes about the Incident App DB

- The demo app uses **SQLite** (file `instance/site.db` inside project). Deleting that file resets all users/data.
- If you delete the DB file, either recreate it or redeploy the pod/deployment so the app can re-initialize. Back up any data you need before deleting.
- **Do not** commit any secrets (SMTP credentials, app passwords) into the repository. Use environment variables or a secrets manager.

---

## Deployment & Essential Commands

### Start Minikube (local Kubernetes)
```bash
minikube start
```

### Use Minikube Docker (optional, recommended for local builds)
```bash
eval $(minikube docker-env)
```

### Build & push Docker images
```bash
# Example: webhook receiver image
docker build -f scripts/Dockerfile -t calix114/ansible-webhook-receiver:v2 .
docker push calix114/ansible-webhook-receiver:v2

# Example: incident app image
docker build -t calix114/incident-app:latest .
docker push calix114/incident-app:latest
```

### Apply Kubernetes manifests
```bash
# Namespace
kubectl create ns incident-mgmt

# Deploy components
kubectl apply -f k8s/alertmanager-config.yaml -n incident-mgmt
kubectl apply -f k8s/alertmanager-deployment.yaml -n incident-mgmt
kubectl apply -f k8s/prometheus-deployment.yaml -n incident-mgmt
kubectl apply -f k8s/incident-app-deployment.yaml -n incident-mgmt
kubectl apply -f k8s/ansible-webhook-deployment.yaml -n incident-mgmt
kubectl apply -f k8s/ansible-webhook-service.yaml -n incident-mgmt
```

### Port forwarding (local access)
```bash
# AlertManager UI
kubectl port-forward svc/alertmanager -n incident-mgmt 9093:9093

# Prometheus UI
kubectl port-forward svc/prometheus -n incident-mgmt 9095:9090

# Webhook receiver
kubectl port-forward svc/ansible-webhook-service -n incident-mgmt 5001:5001

# Incident App web UI
kubectl port-forward svc/incident-app-service -n incident-mgmt 5000:5000
```

### Check logs
```bash
# Webhook receiver logs
kubectl logs -f deployment/ansible-webhook-receiver -n incident-mgmt

# AlertManager logs
kubectl logs -f deployment/alertmanager -n incident-mgmt

# Incident app logs
kubectl logs -f deployment/incident-app -n incident-mgmt
```

### Trigger a test webhook (manual)
```bash
curl -X POST http://localhost:5001/ \
     -H "Content-Type: application/json" \
     -d '{"alerts":[{"status":"firing","labels":{"alertname":"TestAlert"}}]}'
```

---

## Monitor Script

- The `monitor_alerts.sh` script runs **outside the cluster**, on the **host machine** where `kubectl` and `Ansible` are installed.  
- It watches the webhook receiver pod logs for HTTP `200` responses and automatically runs the Ansible playbook when an alert arrives.

---

## Database Notes & Cautions

- The app uses an on-disk SQLite file (`instance/site.db`) for demo purposes.
- If you delete it, all users and incidents are lost.
- Recreate the DB or redeploy to regenerate it.
- For production, use Postgres or MySQL with persistent storage.

---

## Troubleshooting & Common Commands

- Force Kubernetes to use a newly pushed image:
```bash
kubectl patch deployment ansible-webhook-receiver -n incident-mgmt \
  -p '{"spec":{"template":{"spec":{"containers":[{"name":"ansible-webhook-receiver","imagePullPolicy":"Always"}]}}}}'
kubectl rollout restart deployment/ansible-webhook-receiver -n incident-mgmt
```

- Build without cache and push (to avoid old layers):
```bash
docker build --no-cache -f scripts/Dockerfile -t calix114/ansible-webhook-receiver:v3 .
docker push calix114/ansible-webhook-receiver:v3
kubectl set image deployment/ansible-webhook-receiver ansible-webhook-receiver=calix114/ansible-webhook-receiver:v3 -n incident-mgmt
kubectl rollout status deployment/ansible-webhook-receiver -n incident-mgmt
```

- If Minikube is used and images are built locally:
```bash
eval $(minikube docker-env)
docker build -f scripts/Dockerfile -t calix114/ansible-webhook-receiver:v2 .
```

---

## Security & Best Practices

- **Do not** commit SMTP credentials or sensitive info into GitHub.  
- Keep the webhook container lightweight — `kubectl` and `ansible` should run on host/controller nodes.  
- For production, consider:
  - Using Kubernetes Secrets for credentials  
  - Service Accounts + RBAC for secure automation  
  - Ansible `k8s` modules instead of shell commands  
  - Deploying behind Gunicorn + TLS

---

## Short Demo Checklist (for interviews)

1. Start Minikube and port-forward Prometheus, AlertManager, Webhook, and the App.  
2. Show the Incident App UI: create, assign, and resolve an incident — show email notifications.  
3. Simulate or trigger a test alert from AlertManager.  
4. Show webhook pod logs receiving the alert (HTTP 200).  
5. Show `monitor_alerts.sh` detecting HTTP 200 and running Ansible playbook.  
6. Show Ansible restarting or scaling the Kubernetes deployment.  
7. Explain design: lightweight webhook, external automation, and future plan to full in-cluster automation.

---
## documentation will be provided soon 
**End of README**
