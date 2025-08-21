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