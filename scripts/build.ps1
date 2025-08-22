param([string]$Tag)
$ErrorActionPreference = "Stop"

$projRoot = Split-Path $PSScriptRoot -Parent
Set-Location $projRoot

function Get-ProjectVersion {
  try {
    [xml]$pom = Get-Content -Raw -Encoding UTF8 ".\pom.xml"
    $v = $pom.project.version
    if ($v) { return $v.Trim() }
  } catch { }
  $v2 = & mvn -q help:evaluate -Dexpression=project.version -DforceStdout 2>$null
  if ($v2) {
    $v2 = $v2 | Where-Object { $_ -match '^\d+\.\d+\.\d+(-SNAPSHOT)?$' } | Select-Object -First 1
    if ($v2) { return $v2.Trim() }
  }
  throw "Não foi possível obter a versão do projeto."
}

if (-not $Tag -or $Tag.Trim() -eq "") { $Tag = Get-ProjectVersion }

Write-Host "Usando tag: $Tag"
mvn clean package 
docker build -t "rb/getting-started:$Tag" -f Dockerfile .
minikube image load "rb/getting-started:$Tag"
Write-Host "Imagem pronta: rb/getting-started:$Tag"
