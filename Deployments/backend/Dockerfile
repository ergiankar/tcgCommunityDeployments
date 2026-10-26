
# syntax=docker/dockerfile:1

# ---------- Etapa 1: build ----------
FROM maven:3.9.9-eclipse-temurin-21 AS build

WORKDIR /workspace

COPY pom.xml mvnw ./
COPY .mvn/ .mvn/

RUN chmod +x mvnw

RUN ./mvnw -B -ntp dependency:go-offline

COPY src/ src/

# Las pruebas se ejecutarán en una fase específica de CI.
RUN ./mvnw -B -ntp clean package -DskipTests

# Comprobar que existe exactamente un JAR ejecutable.
RUN set -eu; \
    set -- target/*.jar; \
    if [ "$#" -ne 1 ] || [ ! -f "$1" ]; then \
      echo "ERROR: se esperaba exactamente un JAR en target/"; \
      exit 1; \
    fi; \
    mkdir -p /out; \
    cp "$1" /out/app.jar

# ---------- Etapa 2: runtime ----------
FROM eclipse-temurin:21-jre-noble

WORKDIR /app

RUN groupadd --system spring \
    && useradd --system --gid spring --no-create-home spring

COPY --from=build --chown=spring:spring /out/app.jar /app/app.jar

USER spring

EXPOSE 8080

ENV JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=75.0"

ENTRYPOINT ["java", "-jar", "/app/app.jar"]
