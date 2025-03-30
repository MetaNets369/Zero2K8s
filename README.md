```
# Zero2K8s

- Playing with Kubernetes and AI tech. Starting from zero for anyone to follow along.

## What's This About?
- Hands-on experiments with Kubernetes, AI, monitoring, IaC, and maybe some blockchain. Started: March 8, 2025.
- This project follows the "Zero2K8s: A 10-Week Program" (see `docs/10_Week_Program_V2.md` - *Note: You might want to add the program description file here*).

## Progress Log

- **March 9, 2025 (Week 1):** Set up home lab (Ubuntu 24.04). Installed Minikube (v1.35.0) running Kubernetes v1.32.0. Deployed basic Nginx via Docker and then to Minikube. Used GitKraken for dev -> main workflow. Repo created under Apache License.
- **March 16-30, 2025 (Week 2 - Part 1: Manual Setup & Archive):** Built initial CI/CD pipeline (GitHub Actions) for the COP (FastAPI app) including mock MCP tests. Deployed COP, Prometheus, Grafana manually using individual Kubernetes manifests (`k8s/*.yaml`) and `kubectl apply`. Verified functionality locally (Prometheus scraping COP, UIs loading). Fixed CI/CD namespace issue. Archived this working manual state to the `BaseStack-ManualMonitoring` branch for educational reference.
- **March 30, 2025 (Week 2 - Part 2: Helm & Community Stack):** Started implementing the Base Stack using Helm on the `BaseStack-CommunityChart` branch. Added `kube-prometheus-stack` as a Helm dependency to `helm/zero2k8s-chart`. Configured `values.yaml` to enable Prometheus/Grafana (with persistence) and disable Alertmanager. Added `ServiceMonitor` template (`templates/cop-servicemonitor.yaml`) for COP discovery. Created `deploy-helm-stack.sh` script for deployment.

## Current State: Helm Chart Deployment (Community Stack)

This section describes the primary setup for the Week 2 Base Stack, deployed using Helm and the standard `kube-prometheus-stack` community chart.

**Components:**
* Minikube (Local Kubernetes v1.32.0)
* Zero2K8s COP (FastAPI App, Docker Image: `metanets/zero2k8s-cop:latest`) - Deployed via parent Helm chart.
* Kube Prometheus Stack (Helm Dependency) - Includes:
    * Prometheus Operator
    * Prometheus (configured via Operator/ServiceMonitor)
    * Grafana (with persistence)
    * node-exporter
    * kube-state-metrics

**Helm Chart Location:**
* The main chart definition is located in `helm/zero2k8s-chart/`.

**Prerequisites:**
* Minikube installed and running.
* `kubectl` installed and configured for Minikube.
* Docker installed.
* Helm v3 installed.

**Deployment:**
1.  Ensure Minikube is running (`minikube status`).
2.  Run the deployment script from the project root (`Zero2K8s/`):
    ```bash
    chmod +x deploy-helm-stack.sh
    ./deploy-helm-stack.sh
    ```
    This script ensures the `zero2k8s` namespace exists, updates Helm dependencies, and runs `helm upgrade --install` to deploy the `zero2k8s-stack` release using the configurations in `helm/zero2k8s-chart/values.yaml`. The `--wait` flag attempts to wait for resources to become ready.

**Verification:**
1.  Check pod status (Note: `kube-prometheus-stack` deploys many pods; allow several minutes for initialization):
    ```bash
    kubectl get pods -n zero2k8s -w
    ```
2.  Check services and access URLs:
    ```bash
    # List services
    kubectl get svc -n zero2k8s
    # Get Minikube access URLs (check for grafana, prometheus, cop)
    minikube service list -n zero2k8s
    ```
3.  Access UIs: Open the URLs provided by `minikube service list` for Grafana (e.g., `zero2k8s-stack-grafana`) and Prometheus (e.g., `zero2k8s-stack-kube-prom-prometheus`) in your browser. Default Grafana login is likely `admin` / `prom-operator` (check `values.yaml`).
4.  Check Prometheus Targets: In the Prometheus UI, go to **Status -> Targets**. Verify the `serviceMonitor/zero2k8s/zero2k8s-stack-cop-sm/0` target (representing the COP service) appears and shows `State: UP`. Other targets from the community stack (node-exporter, kube-state-metrics, etc.) should also appear.
5.  Check COP Root: Access the COP service URL root. It should display: `{"message":"Welcome to Zero2K8s: This is the COP API Endpoint"}`.

**Cleanup:**
```bash
# Uninstall the Helm release
helm uninstall zero2k8s-stack -n zero2k8s

# Delete the namespace (optional, Helm uninstall might remove some resources)
kubectl delete namespace zero2k8s --ignore-not-found=true

```