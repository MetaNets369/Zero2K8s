#!/bin/bash
# deploy-helm-stack.sh
# Deploys the zero2k8s-chart using Helm, including dependencies.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
NAMESPACE="zero2k8s"
CHART_DIR="./helm/zero2k8s-chart" # Path to the Helm chart
RELEASE_NAME="zero2k8s-stack"     # Name for the Helm release
VALUES_FILE="${CHART_DIR}/values.yaml" # Default values file
# --- End Configuration ---

# --- Ensure Namespace Exists ---
echo "Ensuring namespace '${NAMESPACE}' exists..."
kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -
echo "Namespace '${NAMESPACE}' ensured."
echo # Blank line for readability

# --- Update Helm Dependencies ---
echo "Updating Helm dependencies for chart in '${CHART_DIR}'..."
helm dependency update "${CHART_DIR}"
echo "Helm dependencies updated."
echo # Blank line

# --- Deploy/Upgrade Helm Chart ---
echo "Deploying/Upgrading Helm release '${RELEASE_NAME}' in namespace '${NAMESPACE}'..."
# Use 'helm upgrade --install' for idempotency (installs if not present, upgrades if it is)
helm upgrade --install "${RELEASE_NAME}" "${CHART_DIR}" \
  --namespace "${NAMESPACE}" \
  -f "${VALUES_FILE}" \
  --wait # Optional: wait for resources to become ready

echo "Helm deployment command executed for release '${RELEASE_NAME}'."
echo # Blank line

# --- Verification ---
echo "Deployment script finished. Verifying pod status in namespace '${NAMESPACE}' (may take a few minutes for all components to start):"
# List pods in the target namespace - give it a few seconds first
sleep 5 
kubectl get pods -n "${NAMESPACE}" --sort-by=.metadata.creationTimestamp
echo # Blank line
echo "You can check services using: kubectl get svc -n ${NAMESPACE}"
echo "Or use: minikube service list -n ${NAMESPACE}"
echo "Note: It might take several minutes for Prometheus/Grafana pods to fully initialize."

