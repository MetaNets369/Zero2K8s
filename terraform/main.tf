provider "kubernetes" {
  config_path = "~/.kube/config" # Minikube’s config from Week 1
}

resource "null_resource" "minikube_start" {
  provisioner "local-exec" {
    command = "minikube start --driver=docker --kubernetes-version=v1.32.0"
  }
}
