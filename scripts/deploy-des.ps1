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

Write-Host "Implantando DES com tag: $Tag"
kubectl apply -f .\deployment-des.yaml -n des
kubectl apply -f .\service-des.yaml -n des
kubectl set image deploy/getting-started-des getting-started="rb/getting-started:$Tag" -n des
kubectl rollout status deploy/getting-started-des -n des
$Url = & minikube service getting-started-svc-des -n des --url
Write-Host $Url


