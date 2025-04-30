# Changelog 

**Repository:** `[helm-charts]`  
**Helm-Chart-Name:** `[ia-node]`  
**Description:** `Tracks all notable changes, version history, and roadmap toward 1.0.0 following Semantic Versioning.`  
**SPDX-License-Identifier:** `OGL-UK-3.0`  

All notable changes to this repository will be documented in this file. 
This project follows **Semantic Versioning (SemVer)** ([semver.org](https://semver.org/)), using the format: 


`[MAJOR].[MINOR].[PATCH]` 
- **MAJOR** (`X.0.0`) – Incompatible API/feature changes that break backward compatibility. 
- **MINOR** (`0.X.0`) – Backward-compatible new features, enhancements, or functionality changes. 
- **PATCH** (`0.0.X`) – Backward-compatible bug fixes, security updates, or minor corrections. 
- **Pre-release versions** – Use suffixes such as `-alpha`, `-beta`, `-rc.1` (e.g., `2.1.0-beta.1`). 
- **Build metadata** – If needed, use `+build` (e.g., `2.1.0+20250314`). 

---

## [Unreleased] 

### Added 
- Placeholder for upcoming features and enhancements. 

### Fixed 
- Placeholder for bug fixes and security updates. 

### Changed 
- Placeholder for changes to existing functionality. 

---

## [0.90.1] – 2025-04-30

### Features
- default to local keycloak service for the api and secure graph
- revise the default `Fuseki configs` to provide the ability some of the default install options and to install with/without catalog topic
- default hosts to "*" to ease local deployment 

### Additional Notes and Limitations 
- the secure graph component is set to disabled by default at this time, when working with local Kafka Cluster, the Connect component if enabled will have no issues with connecting, however the graph component whilst able to connects, presents a TLS handshake error. Its not believed this to be an issue for cloud equivalent components
- there currently are no supported images at this time for the Access UI or Query UI components but these can be enabled and overridden with test images as these become available

## [0.90.0] – 2025-04-25

### Initial Public Release (Pre-Stable) 

This is the first public release of this repository under NDTP's open-source governance model. 
Since this release is **pre-1.0.0**, changes may still occur that are **not fully backward-compatible**. 

#### Initial Features 

- feature: initial Helm chart to deploy the IA Node application components

#### Known Limitations 
- Some components are subject to change before `1.0.0`.
- Currently only the access api is enabled by default
- Graph component can be enabled, but is still considered experimental at this point, and you may need to reconfigure listeners and certificates to suit your environment.

## Future Roadmap to `1.0.0` 

The `0.90.x` series is part of NDTP’s **pre-stable development cycle**, meaning: 
- **Minor versions (`0.91.0`, `0.92.0`...) introduce features and improvements** leading to a stable `1.0.0`. 
- **Patch versions (`0.90.1`, `0.90.2`...) contain only bug fixes and security updates**. 
- **Backward compatibility is NOT guaranteed until `1.0.0`**, though NDTP aims to minimise breaking changes. 

Once `1.0.0` is reached, future versions will follow **strict SemVer rules**. 

---

## Versioning Policy 

1. **MAJOR updates (`X.0.0`)** – Typically introduce breaking changes that require users to modify their code or configurations. 
- **Breaking changes (default rule)**: Any backward-incompatible modifications require a major version bump. 
- **Non-breaking major updates (exceptional cases)**: A major version may also be incremented if the update represents a significant milestone, such as a shift in governance, a long-term stability commitment, or substantial new functionality that redefines the project’s scope. 
2. **MINOR updates (`0.X.0`)** – New functionality that is backward-compatible. 
3. **PATCH updates (`0.0.X`)** – Bug fixes, performance improvements, or security patches. 
4. **Dependency updates** – A **major dependency upgrade** that introduces breaking changes should trigger a **MAJOR** version bump (once at `1.0.0`). 

---

## How to Update This Changelog 

1. When making changes, update this file under the **Unreleased** section. 
2. Before a new release, move changes from **Unreleased** to a new dated section with a version number. 
3. Follow **Semantic Versioning** rules to categorise changes correctly. 
4. If pre-release versions are used, clearly mark them as `-alpha`, `-beta`, or `-rc.X`. 

---

**Maintained by the National Digital Twin Programme (NDTP).** 

© Crown Copyright 2025. This work has been developed by the National Digital Twin Programme and is legally attributed to the Department for Business and Trade (UK) as the governing entity. 
Licensed under the Open Government Licence v3.0. 
For full licensing terms, see [OGL_LICENSE.md](OGL_LICENSE.md).
