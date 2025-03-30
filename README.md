# Zero2K8s

- Playing with Kubernetes and AI tech. Starting from zero for anyone to follow along.

## What's This About?\
- Casual experiments with Kubernetes, AI, and maybe some blockchain. Started: March 8, 2025.\
- This project follows the "Zero2K8s: A 10-Week Program" (see `docs/10_Week_Program_V2.md` - *Note: You might want to add the program description file here*).

## Progress Log

- **March 9, 2025 (Week 1):** Set up home lab (Ubuntu 24.04, Ryzen 9 5900X, 64GB RAM). Installed Minikube (v1.35.0) running Kubernetes v1.32.0. Deployed a basic Nginx container via Docker and then to Minikube, added a custom header, verified with curl. Used GitKraken for dev -> main workflow on GitHub. Repo created under Apache License.\
- **March 16, 2025 (Week 2 - Part 1):** Built initial CI/CD pipeline with GitHub Actions for the Zero2K8s COP (FastAPI app). Added a mock Anthropic MCP handshake test (`/mcp/handshake`). Resolved Minikube stability issues in Actions using `--wait=all` and `sleep 10`. CI/CD now successfully builds the COP image, starts Minikube, deploys the COP using `kubectl apply`, and tests endpoints. (See commit `cca4af0` and Action runs). Added Prometheus metrics endpoint to COP (`/metrics`) (See commit `7eaf210`).\
- **March 30, 2025 (Week 2 - Part 2):** Implemented manual deployment manifests for Prometheus and Grafana alongside the COP. Created individual YAML files in the `k8s/` directory. Developed a deployment script (`deploy-manual-k8s.sh`) using `kubectl apply` to deploy the full stack (COP, Prometheus, Grafana) into the `zero2k8s` namespace locally on Minikube. Verified all pods reach `Running` state, Prometheus successfully scrapes the COP `/metrics` endpoint, and the COP root `/` endpoint returns a welcome message.

## Current State: Manual Deployment (kubectl apply)

This section describes the current setup deployed using individual Kubernetes manifests and `kubectl apply`. This represents the first stage of setting up the Week 2 Base Stack.

**Components:**\
* Minikube (Local Kubernetes v1.32.0)\
* Zero2K8s COP (FastAPI App, Docker Image: `metanets/zero2k8s-cop:latest`)\
* Prometheus (Manual Deployment, Image: `prom/prometheus:v2.52.0`)\
* Grafana (Manual Deployment, Image: `grafana/grafana:10.0.3`)

**Manifests Location:**\
* All Kubernetes YAML manifests are located in the `k8s/` directory.

**Prerequisites:**\
* Minikube installed and running.\
* `kubectl` installed and configured for Minikube.\
* Docker installed.\
* Conda environment (`Zero2K8s-3.9`) activated (optional, if running scripts locally that depend on it).

**Deployment:**\
1\.  Ensure Minikube is running (`minikube status`).\
2\.  Ensure the `k8s/` directory contains all necessary manifests (`cop-deployment.yaml`, `prometheus-*.yaml`, `grafana-*.yaml`, etc.).\
3\.  Run the deployment script from the project root:\
    ```bash\
    chmod +x deploy-manual-k8s.sh\
    ./deploy-manual-k8s.sh\
    ```\
    This script creates the `zero2k8s` namespace and applies all manifests in the `k8s/` directory.

**Verification:**\
1\.  Check pod status (wait for them to become `Running`):\
    ```bash\
    kubectl get pods -n zero2k8s -w\
    ```\
2\.  Check services and access URLs:\
    ```bash\
    # List services\
    kubectl get svc -n zero2k8s\
    # Get Minikube access URLs\
    minikube service list -n zero2k8s\
    ```\
3\.  Access UIs: Open the URLs provided by `minikube service list` for Grafana and Prometheus in your browser.\
4\.  Check Prometheus Targets: In the Prometheus UI, go to **Status -> Targets**. Verify both `prometheus` and `zero2k8s-cop` jobs show targets with `State: UP`.\
5\.  Check COP Root: Access the COP service URL root. It should display: `{"message":"Welcome to Zero2K8s: This is the COP API Endpoint"}`.

**Cleanup:**\
```bash\
# Delete deployed resources and namespace\
kubectl delete namespace zero2k8s --ignore-not-found=true\
# Delete manually created PVs\
kubectl delete pv prometheus-pv grafana-pv --ignore-not-found=true