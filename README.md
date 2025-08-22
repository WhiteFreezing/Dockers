# ☕ Dockerized Java Runtimes

> 🚀 Prebuilt, lightweight, and secure Docker images for multiple Java distributions and versions  
> 📦 Auto-built & published to [GitHub Container Registry (GHCR)](https://ghcr.io)  
> 🔐 Official images, built with best practices ✅

This repository automates the generation and maintenance of Docker images for popular OpenJDK implementations across Java 8, 11, 17, and 21.

---

## 📦 Available Distributions & Versions

| Distribution | Java Versions | Base Image | 🏷️ Tags |
|-------------|---------------|------------|--------|
| 🏷️ [Adoptium (Eclipse Temurin)](https://adoptium.net) | 8, 11, 17, 21 | `eclipse-temurin` | `ghcr.io/your-org/adoptium:8-jdk`, etc. |
| 🔵 [Zulu (Azul)](https://www.azul.com) | 8, 11, 17, 21 | `azul/zulu-openjdk` | `ghcr.io/your-org/zulu:11-jdk`, etc. |
| 🟨 [Amazon Corretto](https://aws.amazon.com/corretto/) | 8, 11, 17, 21 | `amazoncorretto` | `ghcr.io/your-org/corretto:17-jdk`, etc. |
| 🌿 [Liberica (BellSoft)](https://bell-sw.com) | 8, 11, 17, 21 | `bellsoft/liberica-openjdk-alpine` | `ghcr.io/your-org/liberica:21-jdk`, etc. |

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
└── liberica/
    ├── 8/Dockerfile
    ├── 11/Dockerfile
    ├── 17/Dockerfile
    └── 21/Dockerfile