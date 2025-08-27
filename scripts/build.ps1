param(
  [string]$Tag
)
$ErrorActionPreference = "Stop"

# =========================
# Padrões de nomenclatura
# =========================
$SISTEMA  = "HACKATHON"
$PROJECT  = "rb"

# Lê artifactId e version do pom.xml
function Get-ProjectInfo {
  $pomPath = Join-Path -Path (Get-Location) -ChildPath "pom.xml"
  if (-not (Test-Path $pomPath)) { throw "pom.xml não encontrado em $pomPath" }
  [xml]$pom = Get-Content -Raw -Path $pomPath
  return @{
    artifactId = $pom.project.artifactId
    version    = $pom.project.version
  }
}

$projInfo = Get-ProjectInfo
$MODULO   = $projInfo.artifactId
$version  = $projInfo.version
$REPO     = "$PROJECT/$MODULO"     # => rb/getting-started
$PIPELINE = "$SISTEMA-$MODULO-build"

Write-Host "==> $PIPELINE"

function Get-ProjectVersion {
  if ($projInfo.version) { return $projInfo.version }
  return "0.0.0-SNAPSHOT"
}

function Test-Command($cmd) {
  return [bool](Get-Command $cmd -ErrorAction SilentlyContinue)
}

# Resolve tag se não vier por parâmetro
if (-not $Tag -or $Tag.Trim() -eq "") { $Tag = Get-ProjectVersion }
Write-Host "Usando tag: $Tag"

# =========================
# Build + testes
# =========================
mvn clean verify

# =========================
# Docker build
# =========================
$ImageSnapshot = "${REPO}:${Tag}"
docker build -t $ImageSnapshot -f Dockerfile .

# =========================
# Criar também tag estável (sem -SNAPSHOT)
# =========================
$StableTag = ($Tag -replace "-SNAPSHOT$","")
if ($StableTag -ne $Tag) {
  $ImageStable = "${REPO}:${StableTag}"
  Write-Host ">> Criando tag estável: $ImageStable"
  docker tag $ImageSnapshot $ImageStable
}

# =========================
# Carregar imagens no Minikube
# =========================
if (Test-Command "minikube") {
  try {
    Write-Host ">> Carregando imagem no Minikube: $ImageSnapshot"
    minikube image load $ImageSnapshot
    if ($StableTag -ne $Tag) {
      Write-Host ">> Carregando imagem no Minikube: $ImageStable"
      minikube image load $ImageStable
    }
  } catch {
    Write-Warning "Falha ao carregar imagens no Minikube: $_"
  }
}

Write-Host "Imagem pronta: $ImageSnapshot"
if ($StableTag -ne $Tag) {
  Write-Host "Imagem estável pronta: $ImageStable"
}
