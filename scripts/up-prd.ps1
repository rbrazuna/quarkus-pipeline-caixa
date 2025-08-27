# up-prd.ps1
# Build + deploy em PRD em um único comando.
# Uso recomendado:
#   powershell -ExecutionPolicy Bypass -File .\scripts\up-prd.ps1

$ErrorActionPreference = 'Stop'

function Run($cmd) {
  Write-Host "==> $cmd" -ForegroundColor Cyan
  iex $cmd
}

# 1) Garantir Minikube ON e contexto correto
try {
  $status = (minikube status) -join ' '
} catch {
  $status = ''
}
if ($status -notmatch 'host: Running' -or $status -notmatch 'kubelet: Running') {
  Run 'minikube start --driver=docker'
}
Run 'kubectl config use-context minikube'
Run 'kubectl get nodes'

# 2) Exibir a versão do projeto (pom.xml)
try {
  $version = & mvn -q help:evaluate "-Dexpression=project.version" "-DforceStdout"
  if (-not [string]::IsNullOrWhiteSpace($version)) {
    Write-Host ("Versão do projeto: {0}" -f $version) -ForegroundColor Yellow
  }
} catch {
  Write-Warning "Não foi possível obter a versão do Maven (ok prosseguir)."
}

# 3) Build (reutiliza o script existente)
$root = $PSScriptRoot
$build = Join-Path $root 'build.ps1'
if (-not (Test-Path $build)) { throw "Script não encontrado: $build" }
Run "powershell -NoProfile -ExecutionPolicy Bypass -File `"$build`""

# 4) Deploy PRD (reutiliza o script existente)
$deployPrd = Join-Path $root 'deploy-prd.ps1'
if (-not (Test-Path $deployPrd)) { throw "Script não encontrado: $deployPrd" }
Run "powershell -NoProfile -ExecutionPolicy Bypass -File `"$deployPrd`""

# 5) Espera básica pelos pods em PRD
Run 'kubectl -n prd get pods'
Run 'kubectl -n prd wait --for=condition=Ready pods --all --timeout=120s'

Write-Host "PRD pronto." -ForegroundColor Green
