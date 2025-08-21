# Promove a versão atual para PRD (retira -SNAPSHOT), carrega no Minikube e faz rollout
param([string]$Tag)   # ex.: 1.0.2-SNAPSHOT (opcional)
$ErrorActionPreference = "Stop"

# 1) Descobre a versão do POM se não for passada
if (-not $Tag) {
  $Tag = (& mvn -q help:evaluate -Dexpression=project.version -DforceStdout)
}

# 2) Cria a tag estável removendo o sufixo -SNAPSHOT, se existir
if ($Tag -match "-SNAPSHOT$") {
  $StableTag = $Tag -replace "-SNAPSHOT$",""
} else {
  $StableTag = $Tag
}

Write-Host "Promovendo $Tag => $StableTag"

# 3) Retag da imagem local para a tag estável (mesmo conteúdo)
docker tag "rb/getting-started:$Tag" "rb/getting-started:$StableTag"

# 4) Disponibiliza a imagem no cluster
minikube image load "rb/getting-started:$StableTag"

# 5) Garante manifests aplicados (idempotente) e troca a imagem do PRD
kubectl apply -f .\deployment-prd.yaml -n prd
kubectl apply -f .\service-prd.yaml -n prd
kubectl set image deploy/getting-started-prd getting-started="rb/getting-started:$StableTag" -n prd

# 6) Acompanha o rollout até concluir
kubectl rollout status deploy/getting-started-prd -n prd

# 7) Mostra a URL pra validar
minikube service getting-started-svc-prd -n prd --url
Write-Host "Aplicado PRD com a imagem: rb/getting-started:$StableTag"