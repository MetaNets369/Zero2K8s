I’m summing up everything we smashed today on my Zero2K8s journey. My CI/CD pipeline was busted, failing to connect to my Minikube service even with a “successful” rollout. I was testing my mock Anthropic MCP (Model Context Protocol) endpoint at /mcp/handshake, and it kept hitting issues.

Here’s what I pulled off:

I kicked things off by debugging my local setup. Ran my zero2k8s-cop container in Docker, hit /mcp/handshake and /metrics, and got back {"response":"Mock MCP handshake successful","data":{"test":"handshake"}} and {"status":"up","version":"1.0"}. My app was good, but Minikube was the problem child.

Next, I tackled Minikube’s issues. It was throwing API Server errors, “connection refused” on localhost:8443. I nuked it with minikube delete --all --purge, cleaned Docker with docker system prune -a -f --volumes, and fired it up with --wait=all to make sure it booted right. Took some retries, but I got it stable.

Then I nailed my local deployment. Pushed my k8s/cop-deployment.yaml to Minikube, saw my pod hit Running, and my service got a CLUSTER-IP. Curls worked after a sleep 10 delay, fixing a routing issue where the service wasn’t ready fast enough.

Introduced 3 guiding rules for commits & push:
Commit Rule #1: Always test the changes locally.
Commit Rule #2: Always stop all dockers and running systems before starting precommit testing.
Commit Rule #3: Always test as best as possible that the GitHubs Actions will not break from commits.

After that, I sorted my CI/CD crash. GitHub Actions was failing ‘cause Minikube rushed. I updated my deploy.yml to use --wait=all in Start Minikube and added sleep 10 in Deploy to Minikube. Tested it locally first (Commit Rule #1), reset my setup (Commit Rule #2), and ran the full thing. Rollout and curls passed every time, proving it wouldn’t break in Actions (Commit Rule #3).

I pushed the fix, commit cca4af0, to BaseStack-Week2. Watched my Actions run green in 2m 4s at https://github.com/MetaNets369/Zero2K8s/actions. My MCP endpoint’s live in CI/CD now.

Finally, I updated my README.md in plain text to flex this win, adding my March 16 progress with MCP details and the Actions link. It’s committed and ready to push.

I’ll confirm this summary’s good by checking my last outputs, then move to the next step. I’ll share my confirmation once I’ve reviewed everything.