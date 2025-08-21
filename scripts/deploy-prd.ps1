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
$StableTag = ($Tag -replace "-SNAPSHOT$","")

Write-Host "Promovendo $Tag => $StableTag"
docker tag "rb/getting-started:$Tag" "rb/getting-started:$StableTag"
minikube image load "rb/getting-started:$StableTag"
kubectl apply -f .\deployment-prd.yaml -n prd
kubectl apply -f .\service-prd.yaml -n prd
kubectl set image deploy/getting-started-prd getting-started="rb/getting-started:$StableTag" -n prd
kubectl rollout status deploy/getting-started-prd -n prd
$Url = & minikube service getting-started-svc-prd -n prd --url
Write-Host $Url
Write-Host "Implantação concluída. Acesse o serviço em: $Url"
Write-Host "Tag estável criada: $StableTag"
    