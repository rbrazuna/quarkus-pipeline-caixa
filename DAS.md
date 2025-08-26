# DAS — HACKATHON / Getting Started (Quarkus)

## 1. Visão Geral
- **Sistema:** HACKATHON
- **Módulo/Serviço:** getting-started (API Quarkus)
- **Objetivo:** Pipeline local para build, empacote e deploy em Kubernetes (DES/PRD) com Docker Desktop + Minikube, análise (SonarQube).
- **Repositório:** este projeto

## 2. Arquitetura Lógica
- **Camadas:** API REST → Service → Repository
- **Tecnologias:** Quarkus 3.x, Java 17 (Temurin), Maven, JUnit/JaCoCo
- **Endpoints de saúde:** `/q/health`, `/q/health/ready`, `/q/health/live`

## 3. Arquitetura de Implantação
- **Ambientes:** 
  - `des` (desenvolvimento) — réplicas: 1 — imagem: `rb/getting-started:1.0.0-SNAPSHOT`
  - `prd` (produção simulada) — réplicas: 2 — imagem: `rb/getting-started:1.0.2`
- **Kubernetes (Minikube):** 
  - Deployments/Services por namespace (`des`, `prd`)
  - Probes configuradas nos manifests
- **Container Base:** `eclipse-temurin:17-jdk-jammy`

## 4. Pipeline Local (CI/CD)
Fluxo automatizado (scripts PowerShell):
1. **Build/Tests/Cobertura:** `mvn clean verify` (JaCoCo gera cobertura)
2. **Análise SAST (opcional no local):** `mvn sonar:sonar` (com `-Dsonar.qualitygate.wait=true` quando SonarQube estiver disponível)
3. **Docker Build:** gera `rb/getting-started:<tag>`
4. **Deploy Kubernetes:** `kubectl apply -f deployment-<amb>.yaml` + `service-<amb>.yaml`
5. **Validação:** `minikube service getting-started-svc-<amb> -n <amb>`

## 5. Padrões de Nomenclatura
- **Pipelines/Jobs (documentação):** `HACKATHON-getting-started-<complemento>`  
  Ex.: `HACKATHON-getting-started-build`, `HACKATHON-getting-started-release-des`, `HACKATHON-getting-started-release-prd`
- **Containers/Instances (referência):** `ci-quarkus-gettingstarted-<env>-extras-###`
- **Kubernetes:** 
  - Deploy DES: `getting-started-des` / Service: `getting-started-svc-des`
  - Deploy PRD: `getting-started-prd` / Service: `getting-started-svc-prd`

## 6. Infra como Código (IaC)
- **Manifests versionados** no repositório (deployment/service para `des` e `prd`)
- Estrutura simples por arquivo: `deployment-des.yaml`, `service-des.yaml`, `deployment-prd.yaml`, `service-prd.yaml`

## 7. Qualidade (SonarQube) — quando utilizado
- **Quality Gate sugerido (novo código):**
  - Cobertura ≥ 80%
  - 0 Vulnerabilities, 0 Bugs (Major+)
  - Duplicação ≤ 3%
  - Security Hotspots revisados
- **Como rodar local:** subir SonarQube (Docker), configurar `SONAR_TOKEN` e executar `mvn ... sonar:sonar -Dsonar.qualitygate.wait=true`.

## 8. Segurança e Segredos
- Tokens (ex.: Sonar) via variáveis de ambiente
- Sem segredos em YAMLs/commits

## 9. Operação
- **Healthchecks:** `/q/health`, `/q/health/ready`, `/q/health/live`
- **Logs:** stdout do container
- **Rollback:** `kubectl rollout undo deploy/<nome> -n <ns>`
- **Acesso local:** `minikube service getting-started-svc-<amb> -n <amb>`

## 10. Passo a Passo Resumido
1. `mvn clean package -DskipTests` (ou `verify` para testes completos)
2. `docker build -t rb/getting-started:1.0.0-SNAPSHOT .`
3. `kubectl apply -f deployment-des.yaml && kubectl apply -f service-des.yaml`
4. `minikube service getting-started-svc-des -n des`
5. (PRD) retag para versão, aplicar `deployment-prd.yaml` e `service-prd.yaml`

## 11. Anexos
- Prints/links: pipeline local, validação em DES/PRD, cobertura de testes (JaCoCo)
