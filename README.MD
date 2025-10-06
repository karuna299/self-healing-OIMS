# Incident Management System (IMS) – Self-Healing Automation

Overview:
The Incident Management System (IMS) is a local deployment project that allows users to create, view, and update incidents.  
Each incident has a description field.  
SMTP notifications are sent automatically to the admin and the assigned engineer whenever a new incident is created.  
Prometheus monitors the health of the IMS application.  
Self-healing automation restarts the IMS application automatically using Ansible when a failure alert is received via the Flask webhook.  

This project uses Docker, Kubernetes (Minikube), Prometheus, Flask, Bash, and Ansible, all deployed locally.

Features:
- Incident Management:
  - Create, view, and update incidents.
  - Each incident includes a description.
  - SMTP notifications are sent automatically on incident creation.
- Self-Healing Automation:
  - Prometheus monitors the application health.
  - Alertmanager sends alerts to the Flask webhook receiver pod.
  - A host-based Bash script monitors webhook logs for HTTP 200 responses.
  - The script triggers an Ansible playbook on the host to restart the IMS application.
- Monitoring:
  - Prometheus for metrics and alerting (ClusterIP).
  - IMS application exposed via NodePort for external access.
  - Grafana can be used locally to visualize Prometheus metrics (scraping the ClusterIP Prometheus endpoint).

## Architecture:
```
+---------------------------------------------------------+
| IMS Application                                         |
| - Exposed via NodePort                                  |
| - Accessible via Minikube service command               |
+-------------------+-------------------------------------+
                    |
            Incident creation
                    v
           SMTP Notifications
                    |
+-------------------+-------------------------------------+
| Prometheus (ClusterIP)                                  |
| - Monitors application health                           |
| - Generates metrics on app failure                      |
+-------------------+-------------------------------------+
                    |
            Alertmanager sends alert
                    v
+-------------------+-------------------------------------+
| Flask Webhook Receiver Pod (ClusterIP)                  |
| - Receives HTTP POST from Alertmanager                  |
+-------------------+-------------------------------------+
                    |
        Host-based Bash script monitors logs
                    |
Triggers Ansible playbook on host
                    |
+-------------------+-------------------------------------+
| IMS Application                                        |
| - Restarts automatically                               |
| - Self-healing ensures continuous availability         |
+---------------------------------------------------------+
```

Tech Stack:
- Python Flask (webhook + IMS backend)
- Docker & Kubernetes (Minikube)
- Prometheus (ClusterIP)
- Bash & Ansible (self-healing automation)
- SMTP (incident notifications)
- Grafana (local, optional)

Notes:
- IMS application runs via NodePort; all other services (Prometheus, webhook receiver) run via ClusterIP.
- The Bash monitoring script is essential for self-healing automation.
- Ensure Ansible is installed on the host machine and paths are correct in the monitoring script.