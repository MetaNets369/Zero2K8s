#!/bin/bash
# deploy-manual-k8s.sh

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
# Define the namespace where resources will be deployed
NAMESPACE="zero2k8s"
# Define the directory containing the Kubernetes manifest files
MANIFEST_DIR="k8s" 

# --- Ensure Namespace Exists ---
echo "Ensuring namespace '${NAMESPACE}' exists..."
# Create the namespace using kubectl apply for idempotency
# This command generates a namespace manifest and applies it.
# If the namespace already exists, kubectl apply will handle it gracefully.
kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -
echo "Namespace '${NAMESPACE}' ensured."
echo # Blank line for readability

# --- Apply Manifests ---
echo "Applying Kubernetes manifests from directory '${MANIFEST_DIR}/' to namespace '${NAMESPACE}'..."
# Check if the manifest directory exists
if [ ! -d "${MANIFEST_DIR}" ]; then
  echo "Error: Manifest directory '${MANIFEST_DIR}' not found."
  echo "Please ensure all required YAML files are in the '${MANIFEST_DIR}' directory."
  exit 1
fi
# Apply all YAML files found in the specified directory
kubectl apply -f "${MANIFEST_DIR}/" -n "${NAMESPACE}"
echo "Successfully applied manifests from '${MANIFEST_DIR}/'."
echo # Blank line

# --- Verification ---
echo "Deployment script finished. Verifying pod status in namespace '${NAMESPACE}':"
# List pods in the target namespace
kubectl get pods -n "${NAMESPACE}"
echo # Blank line
echo "You can check services using: kubectl get svc -n ${NAMESPACE}"
echo "Or use: minikube service list -n ${NAMESPACE}"