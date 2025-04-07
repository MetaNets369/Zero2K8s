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

*(Note: Consider adding `backups/`, `HelmManifest.txt`, `Zero2K8s_FileDump.txt`, `dump_files.py`, `terraform/` to your `.gitignore` file if they are locally generated and shouldn't be tracked in Git).*

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

**Part 2: Helm Deployment & Monitoring**

1.  **Environment Setup:** Ensure Minikube is running (`minikube start ...`) and the `Zero2K8s-3.9` Conda environment is active (`conda activate Zero2K8s-3.9`).
2.  **Deploy:** Run the deployment script from the project root:
    ```bash
    ./deploy-helm-stack.sh
    ```
    This script ensures the `zero2k8s` namespace exists, updates Helm dependencies (pulling `kube-prometheus-stack`), and runs `helm upgrade --install` to deploy/update the release named `zero2k8s-stack`.
3.  **Accessing Services:**
    * **Grafana:** Find the Grafana URL using `minikube service list -n zero2k8s`. Look for `zero2k8s-stack-grafana`. Log in with default credentials `admin` / `prom-operator`.
    * **Prometheus:** Access is typically via port-forwarding:
        ```bash
        kubectl port-forward svc/zero2k8s-stack-kube-promet-prometheus -n zero2k8s 9090:9090
        ```
        Then access `http://localhost:9090` in your browser.
    * **COP Service:** Find the COP URL using `minikube service list -n zero2k8s`. Look for `zero2k8s-stack-zero2k8s-chart-cop-service`. Accessing the root URL should show a welcome message. Accessing `<URL>/metrics` should show Prometheus metrics.
4.  **Verification:**
    * **Prometheus:** Navigate to Status -> Targets. Verify that the target `serviceMonitor/zero2k8s/zero2k8s-stack-zero2k8s-chart-cop-sm/0` exists and shows `State: UP`. This confirms Prometheus is scraping the COP service via the configured `ServiceMonitor`.
    * **Grafana:** Navigate to Dashboards. Find and open the "COP Metrics" dashboard (provisioned automatically via ConfigMap). Verify that the panels show live data being scraped from the COP service.

**Part 3: Backup and Recovery Strategy (Simulated DR)**

This section details how to back up the running stack's persistent data (Prometheus metrics, Grafana DB) and restore it into a simulated fresh environment using Ansible automation.

1.  **Backup:**
    * **Prerequisite:** Ensure `rclone` is installed and configured with a remote (e.g., named `gdrive`) pointing to your desired Google Drive backup location. Use `rclone config` if needed.
    * **Execution:** From the project root (with the `Zero2K8s-3.9` environment active), run the backup script:
        ```bash
        ./backup.sh
        ```
    * **Process:** This script copies data from the live Prometheus/Grafana pods, creates timestamped `.tar.gz` archives in the local `./backups/` directory, and uploads them to the configured `rclone` remote (`gdrive:Zero2K8s-Backups/`).
    * **Verification:** Confirm the script completes successfully and the timestamped archives appear in your Google Drive folder.

2.  **Restore (Simulated DR):**
    * **Goal:** Simulate restoring onto a "bare" machine using the backups and Git repository, automated via Ansible.
    * **Prerequisites (Manual Steps on "Bare" Machine):** Before running the Ansible restore playbook for the *first time* on a new system, ensure the following are installed and configured:
        * Git
        * Miniconda or Anaconda (to provide the `conda` command)
        * Ansible (`pip install ansible` or `conda install ansible`)
        * `kubernetes.core` Ansible collection (`ansible-galaxy collection install kubernetes.core`)
        * Python libraries for the collection (`pip install kubernetes openshift`)
        * `rclone` (`conda install rclone` or download from rclone.org)
        * `rclone` configured with the *same remote name* (e.g., `gdrive`) used by `backup.sh`, pointing to your Google Drive. Use `rclone config`.
        * Docker (required by Minikube docker driver)
        * Minikube
        * kubectl
        * Helm
    * **Automated Restore via Ansible:**
        * Clone the Git repository onto the "bare" machine: `git clone <your-repo-url> Zero2K8s`
        * Navigate into the cloned directory: `cd Zero2K8s`
        * Ensure you are on the correct branch (`git checkout feature/week2-backup-restore` or `main` after merge).
        * Activate a Conda environment where Ansible is installed (e.g., `base` or a dedicated one).
        * Run the Ansible playbook. Make sure the `backup_timestamp` variable inside the playbook matches the backup you want to restore.
            ```bash
            ansible-playbook ansible/restore-env-setup.yml
            ```
            The playbook performs these key steps:
            * Creates a recovery directory (`~/Zero2K8s-Recovered`).
            * Clones the repo again into the recovery directory.
            * Checks required tools are present on the machine running Ansible.
            * Creates the `Zero2K8s-Recovered` Conda environment from `environment.yml`.
            * Downloads the specified backup archives from the `rclone` remote.
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
        * Check Prometheus target for COP is `UP` (use `kubectl port-forward...`).
        * Check Grafana for "COP Metrics" dashboard (use `minikube service list...`).
        * **Crucially:** Verify the Grafana dashboard shows **historical data** from *before* the backup timestamp, confirming successful data restore.

### Week 3 onwards... (To Do)