# ☕ Dockerized Java Runtimes

This repository provides prebuilt Docker images for multiple Java distributions and versions.  
All images are automatically built and published to the [GitHub Container Registry (GHCR)](https://ghcr.io).

## 📦 Available Distributions & Versions

The following Java distributions and versions are available:

- **Adoptium (Temurin)**: `8`, `11`, `17`, `21`
- **Zulu (Azul)**: `8`, `11`, `17`, `21`
- **Amazon Corretto**: `8`, `11`, `17`, `21`
- **Liberica (BellSoft)**: `8`, `11`, `17`, `21`

Each distribution/version has its own Dockerfile inside the repository:
Dockers/
├─ adoptium/8/Dockerfile
├─ adoptium/11/Dockerfile
├─ adoptium/17/Dockerfile
├─ adoptium/21/Dockerfile
├─ zulu/8/Dockerfile