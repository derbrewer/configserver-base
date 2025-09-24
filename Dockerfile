# ------------------------------------------------------------
# Runtime-Stage: Nur das fertige Jar, kein Maven im Dockerfile
# ------------------------------------------------------------
FROM eclipse-temurin:21-jre

WORKDIR /opt/app

# Das von Jenkins gebaute JAR (in stage "Maven Build" erzeugt) kopieren
COPY target/service.jar ./service.jar

# (Optional) Port, auf dem eure Spring-Boot-App lauscht
EXPOSE 8080

# Einfache Startzeile
CMD ["java", "-jar", "service.jar"]