Day 1 Setup Notes: Zero2K8s Environment

Overview

Started messing with some awesome tech today, March 9, 2025, to get my home lab rolling for the "Zero2K8s" project. Goal was to set up a solid environment with Kubernetes and AI stuff, using Git, Docker, and Minikube. This rig’s built tough with an AMD Ryzen 9 5900X 12-Core (24 thread), 2TB SSD, 64GB RAM, powered by Linux on Ubuntu 24.04.2 LTS. Here’s how I got it done.

Cleanup: Wiping the Slate Clean
Had to clear out old stuff to start fresh. Ran these commands to delete everything:

minikube stop - Stopped the Minikube cluster.

minikube delete --all - Nuked the Minikube cluster and profiles.

sudo rm /usr/local/bin/minikube - Removed the Minikube binary.

sudo sh -c "docker ps -a -q | xargs docker stop" - Stopped all Docker containers (fixed permissions issue).

sudo sh -c "docker ps -a -q | xargs docker rm" - Removed all Docker containers.

sudo sh -c "docker images -q | sort -u | xargs docker rmi -f" - Deleted all Docker images.

sudo docker system prune -a --volumes - Cleared out unused Docker data.

Verified with docker ps -a, docker images, and minikube version (failed, as expected).

Setting Up the Environment

Step 1: Install Minikube
Command: curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && sudo install minikube-linux-amd64 /usr/local/bin/minikube

Result: Downloaded and installed Minikube (about 119MB).

Note: Took a few seconds, no issues.

Step 2: Check Minikube Version
Command: minikube version

Result: minikube version: v1.35.0, commit: dd5d320e41b5451cdf3c01891bc4e13d189586ed-dirty

Note: Confirmed it’s the latest version.

Step 3: Start Minikube Cluster
Command: minikube start

Result: Started a cluster with Kubernetes v1.32.0 on Docker 27.4.0, using kvm2 driver. Enabled addons like storage-provisioner.

Note: Took a bit to download images (345MB boot, 333MB preload), but it’s up.

Step 4: Check Docker Status
Command: docker ps

Result: Initially empty (no containers).

Note: Clean slate after cleanup.

Step 5: Run Nginx with Docker
Command: docker run -d -p 80:80 nginx

Result: Pulled nginx:latest, started container with ID b4e012f0bbd0...

Note: Container holds strong on port 80.

Step 6: Check Minikube Nodes
Command: minikube kubectl -- get nodes

Result: NAME STATUS ROLES AGE VERSION (minikube Ready, 87s, v1.32.0)

Note: Cluster node is active.

Step 7: Check Minikube Pods (Before Deployment)
Command: minikube kubectl -- get pods

Result: No resources found in default namespace.

Note: Expected, no pods yet.

Step 8: Create Nginx Deployment
Command: minikube kubectl -- create deployment nginx --image=nginx

Result: deployment.apps/nginx created

Note: Deployed Nginx onto Minikube.

Step 9: Expose Nginx Ports
Command: minikube kubectl -- expose deployment nginx --port=80 --type=NodePort

Result: service/nginx exposed

Note: Opened port 80 for access.

Step 10: Check Minikube Pods (After Deployment)
Command: minikube kubectl -- get pods

Result: NAME READY STATUS RESTARTS AGE (nginx-5869d7778c-5j7bf 1/1 Running 0 14s)

Note: Pod is running, all good.

Configuring Nginx
Action: Entered container with docker exec -it b4e012f0bbd0 /bin/bash.

Install Nano: apt-get update && apt-get install -y nano (installed successfully).

Edit Config: Opened nano /etc/nginx/conf.d/default.conf, added add_header X-Custom-Header "MyLab"; inside the location / block.

Reload: Ran nginx -s reload to apply changes.

Verify: Ran curl -I http://localhost, saw X-Custom-Header: MyLab in the output.

Note: Confirmed Nginx is working with my custom tweak.

GitKraken Setup
Action: Created a branch “dev” in GitKraken, committed “notes/Day1/Setup-env.md” and “screenshots/Day1/” files, merged back to “main”, pushed to “Zero2K8s”.

Note: Tracks my progress, shows branching practice.