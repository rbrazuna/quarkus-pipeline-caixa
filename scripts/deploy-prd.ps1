param(
  [string]$Tag,
  [string]$Group = "grp01"
)

$ErrorActionPreference = "Stop"

# =========================
# Paths e utilidades
# =========================
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

function Test-Command($cmd) { return [bool](Get-Command $cmd -ErrorAction SilentlyContinue) }

function Get-ProjectInfo {
  param([string]$Root)
  $pomPath = Join-Path $Root "pom.xml"
  if (-not (Test-Path $pomPath)) { throw "pom.xml não encontrado em $pomPath" }
  [xml]$pom = Get-Content -Raw -Path $pomPath
  return @{
    artifactId = $pom.project.artifactId
    version    = $pom.project.version
  }
}

# =========================
# Padrões de nomenclatura
# =========================
$projInfo = Get-ProjectInfo -Root $RepoRoot
$SISTEMA  = "HACKATHON"
$PROJECT  = "rb"
$PRODUCT  = $projInfo.artifactId            # ex.: getting-started
$ENV      = "prd"
$REPO     = "$PROJECT/$PRODUCT"             # ex.: rb/getting-started
$PIPELINE = "$SISTEMA-$PRODUCT-release-$ENV"

Write-Host "==> $PIPELINE"

# naming.ps1
$NamingPath = Join-Path $PSScriptRoot "naming.ps1"
if (-not (Test-Path $NamingPath)) { throw "naming.ps1 não encontrado em $NamingPath" }
. $NamingPath

# =========================
# Tag (derivada do pom.xml) e imagem estável
# =========================
if ([string]::IsNullOrWhiteSpace($Tag)) {
  $Tag = $projInfo.version
}
if ([string]::IsNullOrWhiteSpace($Tag)) {
  throw "Tag/versão não encontrada (pom.xml sem <version>?)"
}
$StableTag = ($Tag -replace "-SNAPSHOT$","")
$Image     = "${REPO}:${StableTag}"
Write-Host "Implantando $ENV com imagem estável: $Image"

# =========================
# Manifests
# =========================
$DeployYaml  = Join-Path $RepoRoot "deployment-prd.yaml"
$ServiceYaml = Join-Path $RepoRoot "service-prd.yaml"
if (-not (Test-Path $DeployYaml))  { throw "deployment-prd.yaml não encontrado em $DeployYaml" }
if (-not (Test-Path $ServiceYaml)) { throw "service-prd.yaml não encontrado em $ServiceYaml" }

kubectl apply -f $DeployYaml -n $ENV
kubectl apply -f $ServiceYaml -n $ENV

# =========================
# Define imagem (rb/<artifactId>:<versão estável>)
# =========================
kubectl -n $ENV set image deploy/getting-started-prd getting-started=$Image

# =========================
# PRD em Minikube: usa imagem local (não faz pull)
# =========================
# 1) Se a tag estável não existir localmente, cria a partir do SNAPSHOT
try { docker image inspect $Image | Out-Null } catch {
  try { docker tag "${REPO}:${Tag}" $Image } catch {}
  try { docker tag "${REPO}:${Tag}-SNAPSHOT" $Image } catch {}
}
# 2) Carrega no daemon do Minikube (se disponível)
if (Test-Command "minikube") {
  try { minikube image load $Image } catch { Write-Warning "Falha ao carregar $Image no Minikube: $($_.Exception.Message)" }
}
# 3) imagePullPolicy: Never (evita ImagePullBackOff em ambiente local)
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$patchReplace = '[{"op":"replace","path":"/spec/template/spec/containers/0/imagePullPolicy","value":"Never"}]'
$patchAdd     = '[{"op":"add","path":"/spec/template/spec/containers/0/imagePullPolicy","value":"Never"}]'
$patchFile    = Join-Path $env:TEMP "prd-ippatch.json"
[System.IO.File]::WriteAllText($patchFile, $patchReplace, $utf8NoBom)
$ok = $true
try {
  kubectl -n $ENV patch deploy getting-started-prd --type json --patch-file $patchFile | Out-Null
} catch {
  $ok = $false
}
if (-not $ok) {
  [System.IO.File]::WriteAllText($patchFile, $patchAdd, $utf8NoBom)
  kubectl -n $ENV patch deploy getting-started-prd --type json --patch-file $patchFile | Out-Null
}

# =========================
# Labels (instance)
# =========================
$instance = Get-InstanceName -Project $PROJECT -Product $PRODUCT -Environment $ENV -Group $Group
Write-Host "Aplicando label 'instance=$instance'…"
kubectl -n $ENV label deploy getting-started-prd instance="$instance" --overwrite
kubectl -n $ENV label svc getting-started-svc-prd instance="$instance" --overwrite

# Patch no template do Pod (propaga label)
$patchObj = @{ spec = @{ template = @{ metadata = @{ labels = @{ instance = $instance }}}}}
$patchJson = $patchObj | ConvertTo-Json -Depth 10
$patchFile2 = [System.IO.Path]::GetTempFileName()
Set-Content -Path $patchFile2 -Value $patchJson -Encoding UTF8
try {
  kubectl -n $ENV patch deployment getting-started-prd --type merge --patch-file $patchFile2 | Out-Null
} finally {
  Remove-Item $patchFile2 -Force -ErrorAction SilentlyContinue
}

# =========================
# Rollout + PODs (com timeout p/ não "travar")
# =========================
$timeout = "180s"
kubectl -n $ENV rollout status deploy/getting-started-prd --timeout=$timeout
kubectl -n $ENV get pods -o wide

# =========================
# ABRIR A APLICAÇÃO — SEMPRE VIA PORT-FORWARD (com fallback de porta)
# =========================
try {
  # escolher porta local (8081, se ocupada usa 8082)
  $localPort = 8081
  try {
    $tcp = Test-NetConnection -ComputerName 'localhost' -Port $localPort -WarningAction SilentlyContinue
    if ($tcp.TcpTestSucceeded) { $localPort = 8082 }
  } catch { $localPort = 8081 }

  # abre o port-forward numa nova janela e o browser na URL correta
  Start-Process powershell "-NoExit -Command kubectl -n $ENV port-forward svc/getting-started-svc-prd $localPort`:8080"
  Start-Sleep -Seconds 2
  $url = "http://localhost:$localPort/hello"
  Write-Host "Aplicação (PRD) disponível em: $url"
  Start-Process $url
} catch {
  Write-Host "Falhou ao iniciar port-forward: $($_.Exception.Message)"
  Write-Host "Alternativa manual:"
  Write-Host "  kubectl -n $ENV port-forward svc/getting-started-svc-prd 8081:8080"
  Write-Host "  Depois acesse: http://localhost:8081/hello"
}
