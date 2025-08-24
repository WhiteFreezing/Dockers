# ☕ Dockerized Java Runtimes for Minecraft

> 🚀 Prebuilt, lightweight, and secure Docker images for Java distributions suitable for Minecraft servers  
> 📦 Auto-built & published to [GitHub Container Registry (GHCR)](https://ghcr.io)  
> 🔐 Official images, built with best practices ✅

This repository automates the generation and maintenance of Docker images for popular OpenJDK implementations across multiple Java versions.

---

## 📦 Available Distributions & Versions (Minecraft-focused)

| Distribution                                           | Java Versions | Base Image                         | 🏷️ Tags                                                      |
| ------------------------------------------------------ | ------------- | ---------------------------------- | ------------------------------------------------------------- |
| 🏷️ [Adoptium (Eclipse Temurin)](https://adoptium.net) | 8, 11, 17, 22, 23, 24 | `eclipse-temurin`                  | `ghcr.io/whitefreezing/java:adoptium-8`, …, `adoptium-22`    |
| 🔵 [Zulu (Azul)](https://www.azul.com)                 | 8, 11, 17, 22, 23, 24 | `azul/zulu-openjdk-debian`         | `ghcr.io/whitefreezing/java:zulu-8`, …, `zulu-22`            |
| 🟨 [Amazon Corretto](https://aws.amazon.com/corretto/) | 8, 11, 17, 22, 23, 24 | `amazoncorretto`                   | `ghcr.io/whitefreezing/java:corretto-8`, …, `corretto-22`    |
| 🌿 [Liberica (BellSoft)](https://bell-sw.com)          | 8, 11, 17, 22, 23, 24 | `bellsoft/liberica-openjdk-debian` | `ghcr.io/whitefreezing/java:liberica-8`, …, `liberica-22`    |
| 🟥 [SAPMachine](https://sap.github.io/SapMachine/)     | 8, 11, 17, 22, 23, 24 | `sapmachine`                       | `ghcr.io/whitefreezing/java:sapmachine-8`, …, `sapmachine-22`|

> 💡 **All images are built using official upstream images and are tagged consistently.**  
> 💡 **Removed GraalVM, Dragonwell, BellSoft Full, OpenJ9, and Shipilev for Minecraft-focused usage.**

---

## 📁 Repository Structure (Minecraft-focused)

```bash
Dockers/
├── adoptium/
│   ├── 8/Dockerfile
│   ├── 11/Dockerfile
│   ├── 17/Dockerfile
│   └── 22/Dockerfile
├── zulu/
│   ├── 8/Dockerfile
│   ├── 11/Dockerfile
│   ├── 17/Dockerfile
│   └── 22/Dockerfile
├── corretto/
│   ├── 8/Dockerfile
│   ├── 11/Dockerfile
│   ├── 17/Dockerfile
│   └── 22/Dockerfile
├── liberica/
│   ├── 8/Dockerfile
│   ├── 11/Dockerfile
│   ├── 17/Dockerfile
│   └── 22/Dockerfile
└── sapmachine/
    ├── 8/Dockerfile
    ├── 11/Dockerfile
    ├── 17/Dockerfile
    └── 22/Dockerfile
