## Zero2K8s

- Playing with Kubernetes and AI tech. Starting from zero for anyone to follow along. 

### What’s This About?
- Casual experiments with Kubernetes, AI, and maybe some blockchain. Started: March 8, 2025.

### Progress
- March 9, 2025: Set up my home lab on Ubuntu 24.04 with an AMD Ryzen 9 5900X, 64GB RAM, and 2TB SSD. Got Minikube running Kubernetes v1.32.0, deployed a basic Nginx pod, and tweaked it with a custom header. Pushed initial notes and screenshots to GitHub.
- March 16, 2025: Built a dope CI/CD pipeline with GitHub Actions for my Zero2K8s COP (Central Orchestration Platform). Added a mock Anthropic MCP (Model Context Protocol) test. It hits /mcp/handshake endpoint in Minikube, returns {"response":"Mock MCP handshake successful","data":{"test":"handshake"}}. Fixed Minikube issues with --wait=all and a sleep 10 for service routing. Runs clean in 2m 4s
- Review GitHub Actions with a green run: https://github.com/MetaNets369/Zero2K8s/actions

### Next Steps
- Hook up a real Anthropic MCP SDK when I get my hands on it.
- Maybe mess with some blockchain nodes or AI model deployments.