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
$PRODUCT  = $projInfo.artifactId
$ENV      = "des"
$REPO     = "$PROJECT/$PRODUCT"
$PIPELINE = "$SISTEMA-$PRODUCT-release-$ENV"

Write-Host "==> $PIPELINE"

# naming.ps1
$NamingPath = Join-Path $PSScriptRoot "naming.ps1"
if (-not (Test-Path $NamingPath)) { throw "naming.ps1 não encontrado em $NamingPath" }
. $NamingPath

# =========================
# Namespace
# =========================
if (-not (kubectl get ns $ENV -o name 2>$null)) {
  Write-Host "Namespace '$ENV' não existe. Criando…"
  kubectl create ns $ENV | Out-Null
}

# =========================
# Tag e imagem
# =========================
if ([string]::IsNullOrWhiteSpace($Tag)) {
  $Tag = $projInfo.version
}
if ([string]::IsNullOrWhiteSpace($Tag)) {
  throw "Tag/versão não encontrada (pom.xml sem <version>?)"
}
$Image = "${REPO}:${Tag}"
Write-Host "Implantando $ENV com imagem: $Image"

# =========================
# Manifests
# =========================
$DeployYaml  = Join-Path $RepoRoot "deployment-des.yaml"
$ServiceYaml = Join-Path $RepoRoot "service-des.yaml"
if (-not (Test-Path $DeployYaml))  { throw "deployment-des.yaml não encontrado em $DeployYaml" }
if (-not (Test-Path $ServiceYaml)) { throw "service-des.yaml não encontrado em $ServiceYaml" }

kubectl apply -f $DeployYaml -n $ENV
kubectl apply -f $ServiceYaml -n $ENV

# =========================
# Define imagem
# =========================
kubectl -n $ENV set image deploy/getting-started-des getting-started=$Image

# =========================
# Evita ImagePullBackOff (DES usa imagem local)
# =========================
try {
  kubectl -n $ENV patch deploy getting-started-des --type json `
    -p '[{"op":"replace","path":"/spec/template/spec/containers/0/imagePullPolicy","value":"Never"}]' | Out-Null
} catch {
  kubectl -n $ENV patch deploy getting-started-des --type json `
    -p '[{"op":"add","path":"/spec/template/spec/containers/0/imagePullPolicy","value":"Never"}]' | Out-Null
}

# =========================
# Labels
# =========================
$instance = Get-InstanceName -Project $PROJECT -Product $PRODUCT -Environment $ENV -Group $Group
Write-Host "Aplicando label 'instance=$instance'…"
kubectl -n $ENV label deploy getting-started-des instance="$instance" --overwrite
kubectl -n $ENV label svc getting-started-svc-des instance="$instance" --overwrite

# Patch no template do Pod (propaga label)
$patchObj = @{
  spec = @{
    template = @{
      metadata = @{
        labels = @{ instance = $instance }
      }
    }
  }
}
$patchJson = $patchObj | ConvertTo-Json -Depth 10
$patchFile = [System.IO.Path]::GetTempFileName()
Set-Content -Path $patchFile -Value $patchJson -Encoding UTF8
try {
  kubectl -n $ENV patch deployment getting-started-des --type merge --patch-file $patchFile | Out-Null
} finally {
  Remove-Item $patchFile -Force -ErrorAction SilentlyContinue
}

# =========================
# Rollout + PODs
# =========================
kubectl -n $ENV rollout status deploy/getting-started-des
kubectl -n $ENV get pods -o wide

# =========================
# URL estável via port-forward (não bloqueia este script) e abre navegador
# =========================
try {
  Start-Process powershell "-NoExit -Command kubectl -n $ENV port-forward svc/getting-started-svc-des 8080:8080"
  Start-Sleep -Seconds 2
  $url = "http://localhost:8080/hello"
  Write-Host "Aplicação (DES) disponível em: $url"
  Start-Process $url
} catch {
  Write-Host "Falhou ao iniciar port-forward: $($_.Exception.Message)"
  Write-Host "Alternativa manual:"
  Write-Host "  kubectl -n $ENV port-forward svc/getting-started-svc-des 8080:8080"
  Write-Host "  Depois acesse: http://localhost:8080/hello"
}
