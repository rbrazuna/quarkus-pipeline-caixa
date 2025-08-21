# Compila, gera a imagem e carrega no Minikube
param([string]$Tag)
$ErrorActionPreference = "Stop"

if (-not $Tag) {
  # Lê a versão do pom.xml (ex.: 1.0.2-SNAPSHOT)
  $Tag = (& mvn -q help:evaluate -Dexpression=project.version -DforceStdout)
}

mvn clean package -DskipTests        # limpa e empacota o JAR
docker build -t "rb/getting-started:$Tag" -f Dockerfile .  # constrói a imagem
minikube image load "rb/getting-started:$Tag"              # carrega no cluster
Write-Host "Imagem pronta: rb/getting-started:$Tag"
