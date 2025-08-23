# ☕ Dockerized Java Runtimes

> 🚀 Prebuilt, lightweight, and secure Docker images for multiple Java distributions and versions  
> 📦 Auto-built & published to [GitHub Container Registry (GHCR)](https://ghcr.io)  
> 🔐 Official images, built with best practices ✅

This repository automates the generation and maintenance of Docker images for popular OpenJDK implementations across multiple Java versions.

---

## 📦 Available Distributions & Versions

| Distribution                                           | Java Versions | Base Image                         | 🏷️ Tags                                                      |
| ------------------------------------------------------ | ------------- | ---------------------------------- | ------------------------------------------------------------- |
| 🏷️ [Adoptium (Eclipse Temurin)](https://adoptium.net) | 8–23          | `eclipse-temurin`                  | `ghcr.io/whitefreezing/java:adoptium-8`, …, `adoptium-23`     |
| 🔵 [Zulu (Azul)](https://www.azul.com)                 | 8–23          | `azul/zulu-openjdk-debian`         | `ghcr.io/whitefreezing/java:zulu-8`, …, `zulu-23`             |
| 🟨 [Amazon Corretto](https://aws.amazon.com/corretto/) | 8–23          | `amazoncorretto`                   | `ghcr.io/whitefreezing/java:corretto-8`, …, `corretto-23`     |
| 🌿 [Liberica (BellSoft)](https://bell-sw.com)          | 8–23          | `bellsoft/liberica-openjdk-debian` | `ghcr.io/whitefreezing/java:liberica-8`, …, `liberica-23`     |
| 🟪 [GraalVM](https://www.graalvm.org/)                 | 11–23         | `ghcr.io/graalvm/graalvm-ce`       | `ghcr.io/whitefreezing/java:graalvm-11`, …, `graalvm-23`      |
| 🟥 [SAPMachine](https://sap.github.io/SapMachine/)     | 8–23          | `sapmachine`                       | `ghcr.io/whitefreezing/java:sapmachine-8`, …, `sapmachine-23` |
| 🟫 [Dragonwell](https://dragonwell-jdk.io/)            | 8–21          | `alibaba/dragonwell`               | `ghcr.io/whitefreezing/java:dragonwell-8`, …, `dragonwell-21` |
| 🟩 [BellSoft Full](https://bell-sw.com/)               | 8–23          | `bellsoft/liberica-full`           | `ghcr.io/whitefreezing/java:bellsoft-8`, …, `bellsoft-23`     |
| 🟦 [GraalCE](https://www.graalvm.org/)                 | 11–23         | `ghcr.io/graalvm/graalce`          | `ghcr.io/whitefreezing/java:graalce-11`, …, `graalce-23`      |
| 🟨 [GraalJDK](https://www.graalvm.org/)                | 11–23         | `ghcr.io/graalvm/graaljdk`         | `ghcr.io/whitefreezing/java:graaljdk-11`, …, `graaljdk-23`    |
| ⚫ [OpenJ9 Rocky 21](https://adoptopenjdk.net/)         | 8–23          | `adoptopenjdk/openj9`              | `ghcr.io/whitefreezing/java:openj9_21-8`, …, `openj9_21-23`   |
| 🟤 [Shipilev Rocky 24](https://shipilev.net/)          | 8–23          | `shipilev/openjdk`                 | `ghcr.io/whitefreezing/java:shipilev-8`, …, `shipilev-23`     |

> 💡 **All images are built using official upstream images and are tagged consistently.**

---

## 📁 Repository Structure

```bash
Dockers/
├── adoptium/
│   ├── 8/Dockerfile
│   ├── 11/Dockerfile
│   ├── 17/Dockerfile
│   ├── 21/Dockerfile
│   ├── 22/Dockerfile
│   └── 23/Dockerfile
├── zulu/
│   ├── 8/Dockerfile
│   ├── 11/Dockerfile
│   ├── 17/Dockerfile
│   ├── 21/Dockerfile
│   ├── 22/Dockerfile
│   └── 23/Dockerfile
├── corretto/
│   ├── 8/Dockerfile
│   ├── 11/Dockerfile
│   ├── 17/Dockerfile
│   ├── 21/Dockerfile
│   ├── 22/Dockerfile
│   └── 23/Dockerfile
├── temurin/
│   ├── 8/Dockerfile
│   ├── 11/Dockerfile
│   ├── 17/Dockerfile
│   ├── 21/Dockerfile
│   ├── 22/Dockerfile
│   └── 23/Dockerfile
├── liberica/
│   ├── 8/Dockerfile
│   ├── 11/Dockerfile
│   ├── 17/Dockerfile
│   ├── 21/Dockerfile
│   ├── 22/Dockerfile
│   └── 23/Dockerfile
├── graalvm/
│   ├── 11/Dockerfile
│   ├── 17/Dockerfile
│   ├── 21/Dockerfile
│   ├── 22/Dockerfile
│   └── 23/Dockerfile
├── sapmachine/
│   ├── 8/Dockerfile
│   ├── 11/Dockerfile
│   ├── 17/Dockerfile
│   ├── 21/Dockerfile
│   ├── 22/Dockerfile
│   └── 23/Dockerfile
├── dragonwell/
│   ├── 8/Dockerfile
│   ├── 11/Dockerfile
│   ├── 17/Dockerfile
│   └── 21/Dockerfile
├── bellsoft/
│   ├── 8/Dockerfile
│   ├── 11/Dockerfile
│   ├── 17/Dockerfile
│   ├── 21/Dockerfile
│   ├── 22/Dockerfile
│   └── 23/Dockerfile
├── graalce/
│   ├── 11/Dockerfile
│   ├── 17/Dockerfile
│   ├── 21/Dockerfile
│   ├── 22/Dockerfile
│   └── 23/Dockerfile
├── graaljdk/
│   ├── 11/Dockerfile
│   ├── 17/Dockerfile
│   ├── 21/Dockerfile
│   ├── 22/Dockerfile
│   └── 23/Dockerfile
├── openj9_21-rocky/
│   ├── 8/Dockerfile
│   ├── 11/Dockerfile
│   ├── 17/Dockerfile
│   ├── 21/Dockerfile
│   ├── 22/Dockerfile
│   └── 23/Dockerfile
└── shipilev/24-rocky/
    ├── 8/Dockerfile
    ├── 11/Dockerfile
    ├── 17/Dockerfile
    ├── 21/Dockerfile
    ├── 22/Dockerfile
    └── 23/Dockerfile