# ☕ Dockerized Java Runtimes

> 🚀 Prebuilt, lightweight, and secure Docker images for multiple Java distributions and versions  
> 📦 Auto-built & published to [GitHub Container Registry (GHCR)](https://ghcr.io)  
> 🔐 Official images, built with best practices ✅

This repository automates the generation and maintenance of Docker images for popular OpenJDK implementations across multiple Java versions.

---

## 📦 Available Distributions & Versions

| Distribution | Java Versions | Base Image | 🏷️ Tags |
|-------------|---------------|------------|--------|
| 🏷️ [Adoptium (Eclipse Temurin)](https://adoptium.net) | 8–24 | `eclipse-temurin` | `ghcr.io/whitefreezing/java:adoptium-8`, etc. |
| 🔵 [Zulu (Azul)](https://www.azul.com) | 8–24 | `azul/zulu-openjdk` | `ghcr.io/whitefreezing/java:zulu-11`, etc. |
| 🟨 [Amazon Corretto](https://aws.amazon.com/corretto/) | 8–24 | `amazoncorretto` | `ghcr.io/whitefreezing/java:corretto-17`, etc. |
| 🌿 [Liberica (BellSoft)](https://bell-sw.com) | 8–24 | `bellsoft/liberica-openjdk-alpine` | `ghcr.io/whitefreezing/java:liberica-21`, etc. |
| 🟪 [GraalVM](https://www.graalvm.org/) | 8–24 | `ghcr.io/graalvm/graalvm-ce` | `ghcr.io/whitefreezing/java:graalvm-21`, etc. |
| 🟥 [SAPMachine](https://sap.github.io/SapMachine/) | 8–24 | `sapmachine` | `ghcr.io/whitefreezing/java:sapmachine-21`, etc. |
| 🟫 [Dragonwell](https://dragonwell-jdk.io/) | 8–24 | `alibaba/dragonwell` | `ghcr.io/whitefreezing/java:dragonwell-21`, etc. |
| 🟩 [BellSoft Full](https://bell-sw.com/) | 8–24 | `bellsoft/liberica-full` | `ghcr.io/whitefreezing/java:bellsoft-21`, etc. |
| 🟦 [GraalCE](https://www.graalvm.org/) | 8–24 | `graalvm/graalce` | `ghcr.io/whitefreezing/java:graalce-21`, etc. |
| 🟨 [GraalJDK](https://www.graalvm.org/) | 8–24 | `graalvm/graaljdk` | `ghcr.io/whitefreezing/java:graaljdk-21`, etc. |
| ⚫ [OpenJ9 Rocky 21](https://adoptopenjdk.net/) | 8–24 | `adoptopenjdk/openj9` | `ghcr.io/whitefreezing/java:openj9_21-rocky-21`, etc. |
| 🟤 [Shipilev Rocky 24](https://shipilev.net/) | 8–24 | `shipilev/openjdk` | `ghcr.io/whitefreezing/java:shipilev/24-rocky-21`, etc. |

> 💡 **All images are built using official upstream images and are tagged consistently.**

---

## 📁 Repository Structure

```bash
Dockers/
├── adoptium/
│   ├── 8/Dockerfile
│   ├── 11/Dockerfile
│   ├── 17/Dockerfile
│   └── 21/Dockerfile
├── zulu/
│   ├── 8/Dockerfile
│   ├── 11/Dockerfile
│   ├── 17/Dockerfile
│   └── 21/Dockerfile
├── corretto/
│   ├── 8/Dockerfile
│   ├── 11/Dockerfile
│   ├── 17/Dockerfile
│   └── 21/Dockerfile
├── temurin/
│   ├── 8/Dockerfile
│   ├── 11/Dockerfile
│   ├── 17/Dockerfile
│   └── 21/Dockerfile
├── liberica/
│   ├── 8/Dockerfile
│   ├── 11/Dockerfile
│   ├── 17/Dockerfile
│   └── 21/Dockerfile
├── graalvm/
│   ├── 8/Dockerfile
│   └── 24/Dockerfile
├── sapmachine/
│   ├── 8/Dockerfile
│   └── 24/Dockerfile
├── dragonwell/
│   ├── 8/Dockerfile
│   └── 24/Dockerfile
├── bellsoft/
│   ├── 8/Dockerfile
│   └── 24/Dockerfile
├── graalce/
│   ├── 8/Dockerfile
│   └── 24/Dockerfile
├── graaljdk/
│   ├── 8/Dockerfile
│   └── 24/Dockerfile
├── openj9_21-rocky/
│   ├── 8/Dockerfile
│   └── 24/Dockerfile
└── shipilev/24-rocky/
    ├── 8/Dockerfile
    └── 24/Dockerfile