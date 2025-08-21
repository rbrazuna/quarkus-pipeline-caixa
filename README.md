# Desafio CAIXA DevSecOps - Quarkus Pipeline

## Visão geral
Aplicação **Quarkus Getting Started** empacotada em Docker e implantada em **Kubernetes local (Minikube)** com dois ambientes:
- **DES**: roda `X.Y.Z-SNAPSHOT`
- **PRD**: roda `X.Y.Z` (estável)

## Pré-requisitos (Windows)
- Windows 10/11 com **Docker Desktop**
- **Minikube** com `--driver=docker`
- **kubectl**
- **Java 17 (Temurin)** e **Maven 3.9+**
- (Opcional) **WSL (Ubuntu)** para comandos Maven/plugins

## Estrutura
```
getting-started/
├─ Dockerfile
├─ deployment-des.yaml
├─ service-des.yaml
├─ deployment-prd.yaml
├─ service-prd.yaml
└─ pom.xml
```

## Uso dos scripts

### Build + carregar no cluster (usa versão do `pom.xml`)
```
powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build.ps1
```

## DEPLOY DES (Usa a versão do pom.xml)
```
powershell -ExecutionPolicy Bypass -File .\scripts\deploy-des.ps1
```
# URL: use o comando abaixo numa outra janela para abrir o túnel e testar /hello
```
minikube service getting-started-svc-des -n des --url
```

##DEPLOY PRD (Usa a versão do pom.xml)
```
powershell -ExecutionPolicy Bypass -File .\scripts\deploy-prd.ps1
```
# Ex.: se pom = 1.0.2-SNAPSHOT → promove para 1.0.2
# Para checar a URL:
```
minikube service getting-started-svc-prd -n prd --url
```
