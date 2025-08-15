# --- build stage ---
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app
COPY pom.xml .
RUN mvn -e -B -ntp -q -DskipTests dependency:go-offline
COPY src ./src
RUN mvn -e -B -ntp package -DskipTests

# --- run stage ---
FROM eclipse-temurin:17-jre
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java","-jar","/app/app.jar"]
