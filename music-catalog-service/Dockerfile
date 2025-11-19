# ETAPA 1: Construcción (Build)
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app

# 1. Copiar el POM raíz
COPY pom.xml .

# 2. Copiar los POM de TODOS los módulos (para resolver dependencias)
COPY api-gateway/pom.xml ./api-gateway/
COPY commerce-service/pom.xml ./commerce-service/
COPY community-service/pom.xml ./community-service/
COPY config-server/pom.xml ./config-server/
COPY discovery-server/pom.xml ./discovery-server/
COPY music-catalog-service/pom.xml ./music-catalog-service/

# 3. Descargar dependencias
RUN mvn dependency:go-offline

# 4. Copiar el *contenido completo* de TODOS los módulos
COPY api-gateway ./api-gateway/
COPY commerce-service ./commerce-service/
COPY community-service ./community-service/
COPY config-server ./config-server/
COPY discovery-server ./discovery-server/
COPY music-catalog-service ./music-catalog-service/

# 5. Construir (package) SÓLO el módulo específico
RUN mvn package -DskipTests -pl music-catalog-service -am

# ETAPA 2: Ejecución (Run)
FROM eclipse-temurin:17-jre-focal
WORKDIR /app

# 6. Copiar el JAR del módulo específico
COPY --from=build /app/music-catalog-service/target/*.jar app.jar

# 7. Exponer el puerto específico
EXPOSE 9002

ENTRYPOINT ["java", "-jar", "app.jar"]

