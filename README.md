# Quarkus Pipeline Caixa – DevSecOps Hackathon  

## 📌 Descrição  
Este repositório faz parte do desafio **DevSecOps – Hackathon**, cujo objetivo é automatizar a implantação de uma aplicação **Quarkus** em um cluster **Kubernetes local**, simulando uma pipeline completa de entrega contínua com boas práticas de **DevOps** e **DevSecOps**.  

A aplicação utilizada como base é o **getting-started** do [quarkus-quickstarts](https://github.com/quarkusio/quarkus-quickstarts/tree/main/getting-started).  

---

## 🎯 Objetivos do Projeto  
- Compilação da aplicação Quarkus em **JAR** executável.  
- Criação de **imagem Docker** a partir do build.  
- Deploy automatizado em **Kubernetes** nos ambientes:  
  - **DES** (Desenvolvimento) – para testes e validações.  
  - **PRD** (Produção) – simulação de ambiente final.  
- Implementação de scripts e pipeline local para automação.  
- Uso de boas práticas de **versionamento**, **segurança** e **infra como código**.  

---

## ⚙️ Estrutura do Projeto  
```
📂 quarkus-pipeline-caixa
 ┣ 📂 getting-started           # Projeto Quarkus base
 ┃ ┣ 📂 scripts                 # Scripts de automação em PowerShell
 ┃ ┃ ┣ build.ps1                # Build e criação da imagem Docker
 ┃ ┃ ┣ deploy-des.ps1           # Deploy no ambiente DES
 ┃ ┃ ┣ deploy-prd.ps1           # Deploy no ambiente PRD
 ┃ ┃ ┗ ...  
 ┣ 📂 entrega                   # Arquivo ZIP para submissão
 ┣ 📄 DAS.md                    # Documento de Arquitetura do Sistema
 ┣ 📄 README.md                 # Este documento
 ┗ 📄 pom.xml                   # Configuração Maven do projeto
```

---

## 🚀 Como Executar  

### 1. Pré-requisitos  
- [Docker](https://www.docker.com/)  
- [Kubernetes](https://kubernetes.io/) (minikube ou kind)  
- [PowerShell](https://learn.microsoft.com/powershell/)  
- [Maven](https://maven.apache.org/)  

### 2. Build da aplicação  
```powershell
cd getting-started
./scripts/build.ps1
```

### 3. Deploy em Desenvolvimento (DES)  
```powershell
./scripts/deploy-des.ps1
```

### 4. Deploy em Produção (PRD)  
```powershell
./scripts/deploy-prd.ps1
```

---

## 🛡️ DevSecOps e Qualidade  
- **Versionamento:** adotado controle via `git` com branches dedicadas.  
- **Análise estática:** projeto preparado para integração com **SonarQube**.  
- **Cobertura de testes:** configurada com **JaCoCo**.  
---

## 📄 Documentação  
- [DAS.md](./DAS.md) – Arquitetura e visão técnica do sistema.  
- Scripts PowerShell de automação (infra como código).  
- Documento de instruções de nomenclatura.  
