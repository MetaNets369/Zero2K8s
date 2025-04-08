# Zero2K8s: A 10-Week Program in Systems Engineering and Automation

## Program Overview

Zero2K8s is a 10-week hands-on program tailored for intermediate to advanced learners. It guides you through building a Kubernetes-powered, Infrastructure-as-Code (IaC)-driven system that integrates cloud-native technologies, AI agents, automation, and blockchain. Starting with a local Minikube setup, the program progresses to a fully cloud-deployed portfolio, emphasizing a Central Orchestration Platform (COP) built with FastAPI. The COP serves as the system's hub, managing components via API endpoints and incorporating the Model Context Protocol (MCP) by Anthropic for AI-driven interactions (with a chat interface added in later weeks).

The program leverages industry-standard tools---Terraform, Kubernetes, Docker, Helm, Ansible, Prometheus, Grafana, and GitHub Actions---alongside innovative technologies like MCP, FastAPI, and Web3. Python, managed with Conda, ensures a reproducible development environment. By the end, you'll have a production-ready stack and a professional portfolio demonstrating your ability to design, automate, and scale complex systems while contributing to open-source.

## Project Structure

```
/
|-- ansible/
|   |-- restore-env-setup.yml      # Playbook for setting up restore env & running restore
|-- backups/                     # Local temporary storage for backups (add to .gitignore)
|-- cop/                         # Source code for Central Orchestration Platform (FastAPI)
|   |-- main.py
|   `-- requirements.txt
|-- docker/
|   `-- Dockerfile                 # Dockerfile for COP service
|-- helm/
|   `-- zero2k8s-chart/            # Main Helm chart for the project
|       |-- Chart.yaml
|       |-- Chart.lock
|       |-- values.yaml
|       |-- charts/                  # Subchart dependencies (e.g., kube-prometheus-stack)
|       `-- templates/               # Helm templates
|           |-- _helpers.tpl
|           |-- cop.yaml             # COP Deployment & Service
|           |-- cop-servicemonitor.yaml # ServiceMonitor for COP
|           `-- cop-dashboard-configmap.yaml # ConfigMap for Grafana COP Dashboard
|-- notes/                       # Weekly notes, learnings, commands
|-- screenshots/                 # Screenshots for documentation/portfolio
|-- terraform/                   # Terraform configurations (Optional Cloud Setup)
|-- .github/
|   `-- workflows/
|       `-- github-actions.yml     # CI/CD Pipeline
|-- .gitignore
|-- backup.sh                    # Script to backup Prometheus/Grafana data
|-- deploy-helm-stack.sh         # Script to deploy the Helm chart
|-- environment.yml              # Conda environment definition
|-- LICENSE
`-- README.md                    # This file
```

## Weekly Progress

### Week 1: Baseline Setup & Nginx Stack (Completed)

* **Objective:** Establish local K8s (Minikube), Docker, Conda env, basic Git workflow, deploy simple Nginx.
* **Key Activities:** Installed tools, configured Minikube, basic Docker interaction, simple Nginx deployment via `kubectl`, custom Nginx header added.
* **Status:** Done. See `notes/Day1/` and `screenshots/Day1/`.

### Week 2: Base Stack with Community Monitoring & B/R (Completed)

* **Objective:** Deploy the FastAPI COP application alongside the `kube-prometheus-stack` for robust monitoring. Implement and test a Backup and Recovery strategy using `rclone` and Ansible.
* **Technologies:** Helm, `kube-prometheus-stack` (Prometheus, Grafana), FastAPI, `ServiceMonitor`, Grafana Dashboards-as-Code (ConfigMap), `rclone`, Ansible, `kubectl cp`.

**Part 1: Manual Setup (Archived)**

* *Initial manual deployment steps are archived on the `BaseStack-ManualMonitoring` branch for reference.*

**Part 2: Helm Deployment & Monitoring (Current Approach)**

1.  **Environment Setup:** Ensure Minikube is running (`minikube start ...`) and the `Zero2K8s-3.9` Conda environment is active (`conda activate Zero2K8s-3.9`).
2.  **Deploy:** Run the deployment script from the project root:
    ```bash
    ./deploy-helm-stack.sh
    ```
    This script ensures the `zero2k8s` namespace exists, updates Helm dependencies (pulling `kube-prometheus-stack`), and runs `helm upgrade --install` to deploy/update the release named `zero2k8s-stack`.
3.  **Accessing Services:**
    * **Grafana:** Find the Grafana URL using `minikube service list -n zero2k8s`. Look for `zero2k8s-stack-grafana`. Log in with `admin` / `prom-operator`.
    * **Prometheus:** Access is typically via port-forwarding:
        ```bash
        kubectl port-forward svc/zero2k8s-stack-kube-promet-prometheus -n zero2k8s 9090:9090
        ```
        Then access `http://localhost:9090` in your browser.
    * **COP Service:** Find the COP URL using `minikube service list -n zero2k8s`. Look for `zero2k8s-stack-zero2k8s-chart-cop-service`. Accessing the URL should show `{"message":"Welcome to Zero2K8s: This is the COP API Endpoint"}`. Accessing `<URL>/metrics` should show Prometheus metrics.
4.  **Verification:**
    * **Prometheus:** Navigate to Status -> Targets. Verify that the target `serviceMonitor/zero2k8s/zero2k8s-stack-zero2k8s-chart-cop-sm/0` exists and shows `State: UP`. This confirms Prometheus is scraping the COP service via the `ServiceMonitor`.
    * **Grafana:** Navigate to Dashboards. Find and open the "COP Metrics" dashboard. Verify that the panels show live data being scraped from the COP service.

**Part 3: Backup and Recovery Strategy (Simulated DR)**

This section details how to backup the running stack's persistent data (Prometheus metrics, Grafana DB) and restore it into a simulated fresh environment.

1.  **Backup:**
    * Ensure your `rclone` is configured with a remote (e.g., named `gdrive`) pointing to your Google Drive backup location. See `rclone config`.
    * From the project root (with the `Zero2K8s-3.9` environment active), run the backup script:
        ```bash
        ./backup.sh
        ```
    * This script copies data from the live Prometheus/Grafana pods, creates timestamped `.tar.gz` archives in `./backups/`, and uploads them to the configured `rclone` remote (`gdrive:Zero2K8s-Backups/`). Verify the files appear in Google Drive.

2.  **Restore (Simulated DR):**
    * **Goal:** Simulate restoring onto a "bare" machine using the backups and Git repository.
    * **Prerequisites (Manual Steps on "Bare" Machine):** Before running the Ansible restore playbook, ensure the following are installed and configured:
        * Git
        * Miniconda or Anaconda (to provide the `conda` command)
        * Ansible (`pip install ansible` or `conda install ansible`)
        * `rclone` (`conda install rclone` or download from rclone.org)
        * `rclone` configured with the *same remote name* (e.g., `gdrive`) used by `backup.sh`, pointing to your Google Drive. Use `rclone config`.
        * Docker (required by Minikube docker driver)
        * Minikube
        * kubectl
        * Helm
    * **Automated Restore via Ansible:**
        * Clone the Git repository onto the "bare" machine: `git clone <your-repo-url> Zero2K8s`
        * Navigate into the cloned directory: `cd Zero2K8s`
        * Ensure you are on the correct branch (`git checkout feature/week2-backup-restore`).
        * Run the Ansible playbook. This automates the rest of the process:
            ```bash
            # Ensure Ansible is runnable (e.g., activate base conda env if needed)
            ansible-playbook ansible/restore-env-setup.yml
            ```
            The playbook performs these key steps:
            * Creates a recovery directory (`~/Zero2K8s-Recovered`).
            * Clones the repo again into the recovery directory (ensuring clean state).
            * Checks required tools are present.
            * Creates the `Zero2K8s-Recovered` Conda environment from `environment.yml`.
            * Downloads the latest backup archives (`.tar.gz`) from `rclone` remote to `~/Zero2K8s-Recovered/restore_temp/`.
            * Stops and deletes any existing Minikube instance (default profile).
            * Starts a fresh Minikube instance.
            * Deploys the Helm stack (creating empty PVCs).
            * Scales down Prometheus/Grafana.
            * Force deletes the old pods.
            * Extracts backup archives.
            * Creates temporary helper pods mounting the new PVCs.
            * Copies extracted data into the helper pods (populating PVCs).
            * Deletes helper pods.
            * Scales Prometheus/Grafana back up.
    * **Manual Verification (Post-Ansible Playbook):**
        * Activate the recovery Conda environment: `conda activate Zero2K8s-Recovered`.
        * `cd ~/Zero2K8s-Recovered/Zero2K8s` (if not already there).
        * Check Prometheus target for COP is `UP` (use `kubectl port-forward...` as above).
        * Check Grafana for "COP Metrics" dashboard (use `minikube service list...` as above).
        * **Crucially:** Verify the Grafana dashboard shows **historical data** from *before* the backup timestamp (`20250406_201439`), confirming successful data restore.

### Week 3 onwards... (To Do)

* Plan outlined in `10 Week Program V3`Temporary commit to force merge
Trigger GitHub Action after workflow update
