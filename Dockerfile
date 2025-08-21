# Usando imagem base com JDK 17
FROM eclipse-temurin:17-jdk-jammy

WORKDIR /deployments

# Copia toda a pasta quarkus-app para dentro do container
COPY target/quarkus-app/ /deployments/

EXPOSE 8080

CMD ["java", "-jar", "quarkus-run.jar"]
