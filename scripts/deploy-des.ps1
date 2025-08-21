# Aplica manifests do DES e faz rollout com a tag informada ou do pom.xml
param([string]$Tag)
$ErrorActionPreference = "Stop"

if (-not $Tag) {
  $Tag = (& mvn -q help:evaluate -Dexpression=project.version -DforceStdout)
}

kubectl apply -f .\deployment-des.yaml -n des
kubectl apply -f .\service-des.yaml -n des
kubectl set image deploy/getting-started-des getting-started="rb/getting-started:$Tag" -n des
kubectl rollout status deploy/getting-started-des -n des
minikube service getting-started-svc-des -n des --url
