FROM maven:3.9.6-eclipse-temurin-17 AS build
WORKDIR /app

# Copiar pom padre primero
COPY pom.xml ./
COPY file-service/pom.xml file-service/

# Descargar dependencias
RUN mvn -f file-service/pom.xml dependency:go-offline

# Copiar código fuente
COPY file-service/src file-service/src

# Construir JAR
RUN mvn -f file-service/pom.xml clean package -DskipTests

# Imagen de ejecución
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app

# Copiar JAR del stage de build
COPY --from=build /app/file-service/target/*.jar app.jar

# Crear directorio para uploads
RUN mkdir -p /uploads

# Exponer puerto
EXPOSE 9005

# Ejecutar aplicación
ENTRYPOINT ["java", "-jar", "app.jar"]
