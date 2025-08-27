# up-des.ps1
# Executa build + deploy DES e abre a URL. Idempotente.
$ErrorActionPreference = 'Stop'
function Run($cmd) { Write-Host "==> $cmd" -ForegroundColor Cyan; iex $cmd }

# 1) Cluster ON e contexto certo (Minikube)
try {
  $status = (minikube status) -join ' '
} catch { $status = '' }
if ($status -notmatch 'host: Running' -or $status -notmatch 'kubelet: Running') {
  Run 'minikube start --driver=docker'
}
Run 'kubectl config use-context minikube'
Run 'kubectl get nodes'

# 2) Mostrar versão corrente do projeto (útil para o avaliador)
$version = & mvn -q help:evaluate "-Dexpression=project.version" "-DforceStdout"
Write-Host ("Versão do projeto: {0}" -f $version) -ForegroundColor Yellow

# 3) Build (sempre usando a forma pedida)
$root = $PSScriptRoot
$build = Join-Path $root 'build.ps1'
if (-not (Test-Path $build)) { throw "Script não encontrado: $build" }
Run "powershell -NoProfile -ExecutionPolicy Bypass -File `"$build`""

# 4) Deploy DES
$deployDes = Join-Path $root 'deploy-des.ps1'
if (-not (Test-Path $deployDes)) { throw "Script não encontrado: $deployDes" }
Run "powershell -NoProfile -ExecutionPolicy Bypass -File `"$deployDes`""

# 5) Aguardar pods prontos no namespace des (sem depender do nome do deployment)
Run 'kubectl -n des get pods'
Run 'kubectl -n des wait --for=condition=Ready pods --all --timeout=120s'

# 6) Descobrir URL do serviço e abrir no navegador
$svcName = 'getting-started-svc-des'   # ajuste aqui se seu svc tiver outro nome
try {
  $url = (minikube service $svcName -n des --url)
  if ([string]::IsNullOrWhiteSpace($url)) { throw "URL vazia" }
  Write-Host "Abrindo: $url/hello" -ForegroundColor Green
  Start-Process "$url/hello"
} catch {
  Write-Warning "Não foi possível obter a URL automaticamente. Rode: minikube service $svcName -n des --url"
}

Write-Host "DES pronto. Versão: $version" -ForegroundColor Green
