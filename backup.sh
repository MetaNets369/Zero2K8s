#!/bin/bash
# backup.sh - Backs up Prometheus and Grafana data from the Helm release

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
NAMESPACE="zero2k8s"
# Helm release name used during deployment
RELEASE_NAME="zero2k8s-stack"
# Local directory to store backups temporarily
BACKUP_DIR="./backups"
# Timestamp for backup files
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
# rclone remote configuration name (e.g., 'gdrive') and path
# !!! IMPORTANT: Ensure rclone is configured with this remote name BEFORE running the script !!!
# Example: run 'rclone config' and set up a remote named 'gdrive' pointing to Google Drive.
RCLONE_REMOTE="gdrive" # Adjust if your rclone remote is named differently
RCLONE_PATH="Zero2K8s-Backups" # Folder on the remote drive

# --- Derived Names (Based on Helm chart defaults/structure) ---
# Pod Selectors - Verify these with 'kubectl get pods -n $NAMESPACE --show-labels' if needed
# Note: Prometheus selector uses operator labels, Grafana uses standard app labels
PROMETHEUS_POD_LABEL="app.kubernetes.io/name=prometheus,operator.prometheus.io/name=${RELEASE_NAME}-kube-promet-prometheus" # Corrected Label
GRAFANA_POD_LABEL="app.kubernetes.io/name=grafana,app.kubernetes.io/instance=${RELEASE_NAME}" # Simplified Grafana Label (verify if needed)

# Data directories inside the pods
PROMETHEUS_DATA_DIR="/prometheus"
GRAFANA_DATA_DIR="/var/lib/grafana"

# Local temporary paths
LOCAL_PROM_BACKUP_PATH="${BACKUP_DIR}/prometheus-data_${TIMESTAMP}"
LOCAL_GRAF_BACKUP_PATH="${BACKUP_DIR}/grafana-data_${TIMESTAMP}"
PROM_ARCHIVE_NAME="prometheus-data_${TIMESTAMP}.tar.gz"
GRAF_ARCHIVE_NAME="grafana-data_${TIMESTAMP}.tar.gz"
# --- End Configuration ---

# --- Ensure Backup Directory Exists ---
echo "Ensuring local backup directory exists: ${BACKUP_DIR}"
mkdir -p "${BACKUP_DIR}"
# Clean potential old temporary data before creating new backup
echo "Cleaning up old temporary directories..."
rm -rf "${BACKUP_DIR}/prometheus-data_"* "${BACKUP_DIR}/grafana-data_"* # Clean based on prefix
mkdir -p "${LOCAL_PROM_BACKUP_PATH}" "${LOCAL_GRAF_BACKUP_PATH}"
echo "Local backup directory ready."
echo

# --- Backup Prometheus ---
echo "Starting Prometheus backup..."
# Find the running Prometheus pod (StatefulSet often names them predictably, but labels are safer)
PROMETHEUS_POD=$(kubectl get pods -n "${NAMESPACE}" -l "${PROMETHEUS_POD_LABEL}" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)

if [ -z "$PROMETHEUS_POD" ]; then
    echo "Error: Prometheus pod not found with labels '${PROMETHEUS_POD_LABEL}' in namespace '${NAMESPACE}'."
    echo "Please check the labels using 'kubectl get pods -n ${NAMESPACE} --show-labels'"
    exit 1
fi
echo "Found Prometheus pod: ${PROMETHEUS_POD}"

echo "Copying data from ${PROMETHEUS_POD}:${PROMETHEUS_DATA_DIR} to ${LOCAL_PROM_BACKUP_PATH}..."
# Note: Using 'kubectl cp' on live Prometheus data carries a small risk of data inconsistency.
# A safer production method involves using the Prometheus API snapshot endpoint (requires enabling Admin API).
kubectl cp "${NAMESPACE}/${PROMETHEUS_POD}:${PROMETHEUS_DATA_DIR}" "${LOCAL_PROM_BACKUP_PATH}" -c prometheus
if [ $? -ne 0 ]; then
    echo "Error: kubectl cp failed for Prometheus data."
    exit 1
fi
# Verify copy (check if the target dir contains expected subdirs like 'wal')
# Corrected path: Check directly inside LOCAL_PROM_BACKUP_PATH
if [ -d "${LOCAL_PROM_BACKUP_PATH}/wal" ]; then
   echo "Prometheus data copied successfully (basic check)."
else
   echo "Error: Prometheus data copy verification failed. 'wal' directory not found directly in ${LOCAL_PROM_BACKUP_PATH} or copy incomplete."
   # Optionally list contents on failure for debugging: ls -lAR "${LOCAL_PROM_BACKUP_PATH}"
   exit 1
fi
echo

# --- Backup Grafana ---
echo "Starting Grafana backup..."
# Find *one* running Grafana pod
GRAFANA_POD=$(kubectl get pods -n "${NAMESPACE}" -l "${GRAFANA_POD_LABEL}" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)

if [ -z "$GRAFANA_POD" ]; then
    echo "Error: Grafana pod not found with labels '${GRAFANA_POD_LABEL}' in namespace '${NAMESPACE}'."
    echo "Please check the labels using 'kubectl get pods -n ${NAMESPACE} --show-labels'"
    exit 1
fi
echo "Found Grafana pod: ${GRAFANA_POD}"

echo "Copying data from ${GRAFANA_POD}:${GRAFANA_DATA_DIR} to ${LOCAL_GRAF_BACKUP_PATH}..."
# Note: Using 'kubectl cp' on the live Grafana DB carries a small risk. Stopping Grafana first is safer but disruptive.
kubectl cp "${NAMESPACE}/${GRAFANA_POD}:${GRAFANA_DATA_DIR}" "${LOCAL_GRAF_BACKUP_PATH}" -c grafana
if [ $? -ne 0 ]; then
    echo "Error: kubectl cp failed for Grafana data."
    exit 1
fi
# Verify copy (check for grafana.db)
# Corrected path: Check directly inside LOCAL_GRAF_BACKUP_PATH
if [ -f "${LOCAL_GRAF_BACKUP_PATH}/grafana.db" ]; then
   echo "Grafana data copied successfully (basic check)."
else
   echo "Error: Grafana data copy verification failed. 'grafana.db' not found directly in ${LOCAL_GRAF_BACKUP_PATH} or copy incomplete."
   # Optionally list contents on failure for debugging: ls -lAR "${LOCAL_GRAF_BACKUP_PATH}"
   exit 1
fi
echo

# --- Create Archives ---
echo "Creating compressed archives..."
echo "Archiving Prometheus data to ${BACKUP_DIR}/${PROM_ARCHIVE_NAME}..."
# Note: The -C flag changes directory *before* archiving. We are archiving the contents
# of the LOCAL_PROM_BACKUP_PATH directory itself.
tar -czf "${BACKUP_DIR}/${PROM_ARCHIVE_NAME}" -C "${LOCAL_PROM_BACKUP_PATH}" .
if [ $? -ne 0 ]; then
    echo "Error: Failed to create Prometheus archive."
    exit 1
fi

echo "Archiving Grafana data to ${BACKUP_DIR}/${GRAF_ARCHIVE_NAME}..."
# Note: The -C flag changes directory *before* archiving. We are archiving the contents
# of the LOCAL_GRAF_BACKUP_PATH directory itself.
tar -czf "${BACKUP_DIR}/${GRAF_ARCHIVE_NAME}" -C "${LOCAL_GRAF_BACKUP_PATH}" .
if [ $? -ne 0 ]; then
    echo "Error: Failed to create Grafana archive."
    exit 1
fi
echo "Archives created."
echo

# --- Upload to Remote Storage (rclone) ---
echo "Uploading archives to rclone remote '${RCLONE_REMOTE}:${RCLONE_PATH}'..."
if ! command -v rclone &> /dev/null; then
    echo "Error: rclone command could not be found. Please install and configure rclone."
    exit 1
fi

rclone copy --progress "${BACKUP_DIR}/${PROM_ARCHIVE_NAME}" "${RCLONE_REMOTE}:${RCLONE_PATH}/"
if [ $? -ne 0 ]; then
    echo "Error: rclone upload failed for Prometheus archive. Check rclone configuration and remote path '${RCLONE_REMOTE}:${RCLONE_PATH}'."
    exit 1
fi
rclone copy --progress "${BACKUP_DIR}/${GRAF_ARCHIVE_NAME}" "${RCLONE_REMOTE}:${RCLONE_PATH}/"
if [ $? -ne 0 ]; then
    echo "Error: rclone upload failed for Grafana archive. Check rclone configuration and remote path '${RCLONE_REMOTE}:${RCLONE_PATH}'."
    exit 1
fi
echo "Upload completed successfully."
echo

# --- Cleanup Local Temporary Data ---
echo "Cleaning up local temporary backup data directories..."
rm -rf "${LOCAL_PROM_BACKUP_PATH}" "${LOCAL_GRAF_BACKUP_PATH}"
# Keep local .tar.gz files for safety unless explicitly told otherwise
# echo "Optionally remove local archives: rm -f \"${BACKUP_DIR}/${PROM_ARCHIVE_NAME}\" \"${BACKUP_DIR}/${GRAF_ARCHIVE_NAME}\""
echo "Local directory cleanup complete."
echo

echo "Backup process finished: ${TIMESTAMP}"
