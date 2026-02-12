# Federator Suite Helm Chart

Complete Helm chart for deploying Federator Suite with flexible configuration for local development, AWS EKS, Azure AKS, and GCP GKE environments. The chart uses a **switch-based configuration model** that enables conditional deployment of in-cluster vs external managed services.

## Features

- ✅ **Multi-Cloud Support**: AWS EKS, Azure AKS, GCP GKE, and local KIND
- ✅ **Flexible Service Deployment**: Toggle between in-cluster and external managed Kafka/Valkey
- ✅ **Multi-Organization**: Deploy multiple independent organizations in parallel
- ✅ **Service Mesh Ready**: Optional Istio integration with Gateway/VirtualService
- ✅ **Cloud-Native Auth**: MSK IAM, Azure Event Hubs, GCP Managed Kafka OAUTHBEARER
- ✅ **Storage Options**: AWS S3, Azure Blob Storage, GCP Cloud Storage
- ✅ **Zero-Downtime Updates**: Health checks, readiness probes, Helm tests

## Quick Start

### Local Development (KIND)

```bash
# Single organization
make deploy-local ORG=bcc

# Multiple organizations (separate namespaces)
make deploy-local ORG=env
make deploy-local ORG=heg
make deploy-local ORG=gcp
```

### AWS EKS

```bash
# Deploy BCC organization to dev EKS cluster
make deploy ENV=dev ORG=bcc

# Deploy ENV organization to dev EKS cluster
make deploy ENV=dev ORG=env
```

### Azure AKS

```bash
# Deploy HEG organization to dev AKS cluster
make deploy ENV=dev ORG=heg
```

### GCP GKE

```bash
# Deploy GCP organization to dev GKE cluster
make deploy ENV=dev ORG=gcp
```

## Deployment Scenarios

The chart supports four primary deployment scenarios based on environment and cloud provider:

### 1. Local (KIND) - Development & Testing

**Components**: In-cluster Kafka (Bitnami) + In-cluster Valkey (Bitnami subchart)

```bash
make deploy-local ORG=bcc
```

**Configuration**:
- `kafka.external: false` → Bitnami Kafka chart deploys in-cluster (KRaft mode)
- `valkey.external: false` → Valkey subchart deploys in-cluster
- NodePort services for UI access (30090-30112 range)
- Unique namespaces per org: `ia-federation-bcc`, `ia-federation-env`, etc.

**Access URLs**:
- Server: http://localhost:30080
- Kafka UI: http://localhost:30090
- Valkey UI: http://localhost:30091 (RedisInsight)

---

### 2. AWS EKS - External MSK + External Redis

**Components**: AWS MSK + Elasticache/External Redis

```bash
make deploy ENV=dev ORG=bcc
```

**Configuration**:
- `kafka.external: true` → Uses Amazon MSK with IAM authentication
- `valkey.external: true` → Uses external Redis (Elasticache or in-cluster Redis)
- `federatorServer.serviceAccount.annotations` → IAM Role for Service Accounts (IRSA)
- LoadBalancer services with AWS NLB for internal access
- S3 storage for P12 certificates and data

**Key Values**:
```yaml
kafka:
  external: true
  externalConfig:
    bootstrapServers: "b-1.msk.kafka.region.amazonaws.com:9096"
    securityProtocol: "SASL_SSL"
    saslMechanism: "AWS_MSK_IAM"

valkey:
  external: true
  externalConfig:
    host: "ia-federator-redis-primary.svc.cluster.local"
    port: 6379

federatorServer:
  serviceAccount:
    annotations:
      eks.amazonaws.com/role-arn: "arn:aws:iam::ACCOUNT:role/federator-role"
  config:
    storage:
      provider: "S3"
      s3:
        bucket: "federator-bucket"
        region: "eu-west-2"
```

---

### 3. Azure AKS - External Event Hubs + External Redis

**Components**: Azure Event Hubs (Kafka-compatible) + Redis

```bash
make deploy ENV=dev ORG=heg
```

**Configuration**:
- `kafka.external: true` → Uses Azure Event Hubs with SASL authentication
- `valkey.external: true` → Uses external Redis
- `federatorServer.serviceAccount.annotations` → Azure Workload Identity
- LoadBalancer services with Azure Internal Load Balancer
- Azure Blob Storage for P12 certificates

**Key Values**:
```yaml
kafka:
  external: true
  externalConfig:
    bootstrapServers: "namespace.servicebus.windows.net:9093"
    securityProtocol: "SASL_SSL"
    saslMechanism: "PLAIN"
    saslJaasConfig: "$ConnectionString"

valkey:
  external: true
  externalConfig:
    host: "ia-federator-redis-master.svc.cluster.local"
    port: 6379

federatorServer:
  serviceAccount:
    annotations:
      azure.workload.identity/client-id: "CLIENT_ID"
  config:
    storage:
      provider: "AZURE"
      azure:
        accountName: "storageaccount"
        endpoint: "https://storageaccount.blob.core.windows.net"
```

---

### 4. GCP GKE - External Managed Kafka + Memorystore

**Components**: Google Cloud Managed Kafka + Memorystore for Valkey

```bash
make deploy ENV=dev ORG=gcp
```

**Configuration**:
- `kafka.external: true` → Uses GCP Managed Kafka with OAUTHBEARER
- `valkey.external: true` → Uses Memorystore for Valkey with TLS
- `federatorServer.serviceAccount.annotations` → Workload Identity
- LoadBalancer services for UI access
- GCP Cloud Storage for P12 certificates

**Key Values**:
```yaml
kafka:
  external: true
  externalConfig:
    bootstrapServers: "bootstrap.PROJECT-ID.region.managedkafka.PROJECT-ID.cloud.goog:9092"
    securityProtocol: "SASL_SSL"
    saslMechanism: "OAUTHBEARER"

valkey:
  external: true
  externalConfig:
    host: "10.0.0.3"
    port: 6378
    tls:
      enabled: true

federatorServer:
  serviceAccount:
    annotations:
      iam.gke.io/gcp-service-account: "federator-sa@project.iam.gserviceaccount.com"
  config:
    storage:
      provider: "GCS"
      gcs:
        bucket: "federator-gcs-bucket"
```

---

## Configuration Switches

The chart uses boolean switches to control deployment topology:

| Switch | Default | Effect |
|--------|---------|--------|
| `kafka.external` | `false` | `false` = Bitnami Kafka in-cluster (KRaft mode)<br>`true` = External managed Kafka (MSK, Event Hubs, Managed Kafka) |
| `valkey.external` | `false` | `false` = Valkey subchart in-cluster<br>`true` = External Redis/Memorystore |
| `valkey.enabled` | `true` | Controls Valkey subchart loading. Set to `false` when `external: true` |
| `serviceMesh.istio.enabled` | `false` | `true` = Deploy Istio Gateway and VirtualService resources |
| `kafkaUi.enabled` | `false` | `true` = Deploy Kafka UI for Kafka management |
| `valkeyUi.enabled` | `false` | `true` = Deploy Valkey UI for Redis management |

### Scenario Matrix (testing overlays)

Use these testing-only overlays on top of the base org override to flip Kafka/Valkey modes:

| Cloud | Kafka | Valkey | Files to apply |
|-------|-------|--------|----------------|
| AWS (EKS) | MSK (external) | Elasticache/External | values/overrides/dev/bcc.yaml |
| AWS (EKS) | MSK (external) | In-cluster | values/overrides/dev/bcc.yaml, values/overrides/dev/testing/aws-msk-incluster-valkey.yaml |
| AWS (EKS) | In-cluster | Elasticache/External | values/overrides/dev/bcc.yaml, values/overrides/dev/testing/aws-incluster-kafka-elasticache.yaml |
| AWS (EKS) | In-cluster | In-cluster | values/overrides/dev/bcc.yaml, values/overrides/dev/testing/aws-incluster-kafka-incluster-valkey.yaml |
| Azure (AKS) | Event Hubs (external) | External Redis | values/overrides/dev/heg.yaml |
| Azure (AKS) | In-cluster | External Redis | values/overrides/dev/heg.yaml, values/overrides/dev/testing/aks-incluster-kafka-managed-redis.yaml |
| Azure (AKS) | In-cluster | In-cluster | values/overrides/dev/heg.yaml, values/overrides/dev/testing/aks-incluster-kafka-incluster-valkey.yaml |
| GCP (GKE) | Managed Kafka (external) | Memorystore (external) | values/overrides/dev/gcp.yaml |
| GCP (GKE) | Managed Kafka (external) | In-cluster | values/overrides/dev/gcp.yaml, values/overrides/dev/testing/gcp-managed-kafka-incluster-valkey.yaml |
| GCP (GKE) | In-cluster | Memorystore (external) | values/overrides/dev/gcp.yaml, values/overrides/dev/testing/gcp-incluster-kafka-memorystore.yaml |
| GCP (GKE) | In-cluster | In-cluster | values/overrides/dev/gcp.yaml, values/overrides/dev/testing/gcp-incluster-kafka-incluster-valkey.yaml |

Istio toggle: set `serviceMesh.istio.enabled=true` in the org override (or an overlay) for mesh-enabled deployments.

### Configuration Hierarchy

Values files are layered in this order (later files override earlier):

```bash
helm install <release> . \
  -f values/common-values.yaml \      # Global defaults
  -f values/kafka.yaml \               # Kafka defaults (external: false)
  -f values/valkey.yaml \              # Valkey defaults (external: false)
  -f values/federator.yaml \           # Federator server/client defaults
  -f values/ui.yaml \                  # UI component defaults
  -f values/overrides/dev/bcc.yaml \   # Org-specific + cloud config
  -f values/overrides/dev/secrets/bcc-secrets.yaml  # Secrets
```

---

## Organizations

The chart supports multiple independent organizations:

| Organization | Cloud Provider | Cluster Type | Kafka | Valkey | Storage |
|--------------|----------------|--------------|-------|--------|---------|
| **BCC** | AWS | EKS | MSK (IAM) | External Redis | S3 |
| **ENV** | AWS | EKS | MSK (IAM) | External Redis | S3 |
| **HEG** | Azure | AKS | Event Hubs (SASL) | External Redis | Azure Blob |
| **GCP** | GCP | GKE | Managed Kafka (OAuth) | Memorystore | GCS |

Each organization has:
- Dedicated namespace: `ia-federation-{org}`
- Separate override file: `values/overrides/{env}/{org}.yaml`
- Separate secrets file: `values/overrides/{env}/secrets/{org}-secrets.yaml`
- Independent Kafka topics with prefix: `Deprecated{ORG}.*`

---

---

## Values Structure

### Core Values Files

```
values/
├── common-values.yaml         # Global settings (image defaults, common config)
├── kafka.yaml                 # Kafka configuration (Bitnami chart settings)
├── valkey.yaml                # Valkey configuration (subchart settings)
├── federator.yaml             # Federator server/client defaults
├── ui.yaml                    # Kafka UI and Valkey UI settings
├── dry-run.yaml               # CI/CD testing (no secrets required)
└── overrides/
    ├── local/                 # Local KIND cluster configs
    │   ├── local.yaml        # Shared local settings
    │   ├── bcc.yaml          # BCC local config
    │   ├── env.yaml          # ENV local config
    │   ├── heg.yaml          # HEG local config
    │   ├── gcp.yaml          # GCP local config
    │   └── secrets.yaml      # All local secrets (base64-encoded certs)
    ├── dev/                   # Dev environment configs
    │   ├── bcc.yaml          # BCC AWS EKS + org config
    │   ├── env.yaml          # ENV AWS EKS + org config
    │   ├── heg.yaml          # HEG Azure AKS + org config
    │   ├── gcp.yaml          # GCP GKE + org config
    │   └── secrets/
    │       ├── bcc-secrets.yaml
    │       ├── env-secrets.yaml
    │       ├── heg-secrets.yaml
    │       └── gcp-secrets.yaml
    └── prod/
        └── secrets/
```

### Self-Contained Override Files

Each override file (e.g., `dev/bcc.yaml`) contains:
- Cloud-specific configuration (EKS, AKS, GKE)
- Organization-specific settings (topic prefixes, consumer groups)
- Service annotations (IRSA, Workload Identity)
- Storage configuration (S3, Azure Blob, GCS)
- Kafka/Valkey connection details

This **self-contained approach** means one file has everything needed for deployment.

---

## Common Commands

```bash
# Help
make help                      # Show all available targets

# Local Development
make deploy-local ORG=bcc      # Deploy BCC locally
make deploy-local ORG=env      # Deploy ENV locally (separate namespace)
make deploy-local ORG=heg      # Deploy HEG locally
make deploy-local ORG=gcp      # Deploy GCP locally

# Dev Environment
make deploy ENV=dev ORG=bcc    # Deploy BCC to AWS dev EKS
make deploy ENV=dev ORG=env    # Deploy ENV to AWS dev EKS
make deploy ENV=dev ORG=heg    # Deploy HEG to Azure dev AKS
make deploy ENV=dev ORG=gcp    # Deploy GCP to GCP dev GKE

# Testing
make test                      # Run all Helm tests
make test-render               # Test template rendering (5 scenarios)
make lint                      # Lint Helm chart

# Utilities
make logs-server               # Server logs
make logs-client               # Client logs
make port-forward-all          # Forward all services
make reset                     # Clean and rebuild dependencies
```

---

## Access URLs

### Local (KIND with NodePort)

Default ports for each organization:

**BCC (Port Range: 30080-30091)**
- Server: http://localhost:30080
- Client: http://localhost:30081
- Server Jobs: http://localhost:30085
- Client Jobs: http://localhost:30086
- Kafka UI: http://localhost:30090
- Valkey UI: http://localhost:30091 (RedisInsight)

**ENV (Port Range: 30082-30101)**
- Server: http://localhost:30082
- Client: http://localhost:30083
- Server Jobs: http://localhost:30087
- Client Jobs: http://localhost:30088
- Kafka UI: http://localhost:30092
- Valkey UI: http://localhost:30101 (RedisInsight)

**HEG (Port Range: 30072-30103)**
- Server: http://localhost:30072
- Client: http://localhost:30073
- Kafka UI: http://localhost:30100
- Valkey UI: http://localhost:30103 (RedisInsight)

**GCP (Port Range: 30084-30112)**
- Server: http://localhost:30084
- Client: http://localhost:30085
- Kafka UI: http://localhost:30102
- Valkey UI: http://localhost:30112 (RedisInsight)

### Cloud Environments

Access via Istio Ingress Gateway or LoadBalancer:
- Dev: `https://{org}-federator.dev.ndtp.co.uk`
- Prod: `https://{org}-federator.prod.ndtp.co.uk`

---

## Prerequisites

### Local Development

- [Docker](https://www.docker.com/) (v20+)
- [Kind](https://kind.sigs.k8s.io/) (v0.20+)
- [Kubectl](https://kubernetes.io/docs/tasks/tools/) (v1.28+)
- [Helm](https://helm.sh/) (v3.12+)
- [Make](https://www.gnu.org/software/make/)

### Cloud Deployments

**AWS EKS**:
- AWS CLI configured with credentials
- EKS cluster with IRSA enabled
- MSK cluster or compatible Kafka
- IAM role with MSK and S3 permissions

**Azure AKS**:
- Azure CLI configured
- AKS cluster with Workload Identity enabled
- Event Hubs namespace
- Storage Account for Azure Blob Storage

**GCP GKE**:
- GCloud CLI configured
- GKE cluster with Workload Identity enabled
- Managed Kafka for Apache Kafka cluster
- Memorystore for Valkey instance
- GCS bucket for storage

---

## Testing

The chart includes comprehensive test infrastructure:

### Helm Tests

```bash
# Run Helm tests (pod-based health checks)
helm test <release-name>
```

Tests include:
- Server health check: `/actuator/health`
- Client health check: `/actuator/health`
- Kafka UI accessibility (when enabled)

### Template Rendering Tests

```bash
# Run template rendering validation
make test-render
```

Validates 5 scenarios:
1. `local-bcc` - Local BCC with in-cluster services
2. `local-env` - Local ENV with in-cluster services
3. `local-heg` - Local HEG with in-cluster services
4. `local-gcp` - Local GCP with in-cluster services
5. `dev-gcp` - Dev GCP with external managed services

Each test validates:
- Templates render without errors
- No deprecated Spring Kafka properties
- Kafka bootstrap servers configured
- Redis/Valkey host configured
- Management node URL configured

---

## Documentation

- **[documentation/DEPLOYMENT-GUIDE.md](documentation/DEPLOYMENT-GUIDE.md)** - Step-by-step deployment guide for all cloud providers
- **[documentation/VALUES-REFERENCE.md](documentation/VALUES-REFERENCE.md)** - Complete values reference
- **[documentation/ARCHITECTURE.md](documentation/ARCHITECTURE.md)** - Architecture diagrams and design decisions
- **[documentation/CURRENT-STATUS.md](documentation/CURRENT-STATUS.md)** - Project status and task tracking
- **[values/README.md](values/README.md)** - Values file structure and usage

---

## Troubleshooting

### Templates Not Rendering

```bash
# Check syntax
helm lint .

# Dry-run to see what would be deployed
helm install test . --dry-run --debug \
  -f values/common-values.yaml \
  -f values/kafka.yaml \
  -f values/valkey.yaml \
  -f values/federator.yaml \
  -f values/overrides/dev/bcc.yaml
```

### Pods Not Starting

```bash
# Check pod status
kubectl get pods -n ia-federation

# View pod logs
kubectl logs -n ia-federation <pod-name>

# Describe pod for events
kubectl describe pod -n ia-federation <pod-name>
```

### Kafka Connection Issues

```bash
# Verify Kafka bootstrap servers
kubectl exec -n ia-federation <server-pod> -- cat /config/application.properties | grep bootstrap

# Test Kafka connectivity (AWS MSK IAM)
kubectl exec -n ia-federation <server-pod> -- curl -I https://bootstrap.kafka.region.amazonaws.com:9096
```

### Certificate Issues

Ensure secrets are properly base64-encoded:
```bash
# Encode P12 certificate
base64 -w 0 client.p12

# Verify secret
kubectl get secret federation-client-p12 -n ia-federation -o yaml
```

---

## License

See [LICENSE.md](../../LICENSE.md) for full license details.

---

## Support

For issues, questions, or contributions:
- GitHub Issues: [helm-charts/issues](https://github.com/org/helm-charts/issues)
- Documentation: [documentation/](documentation/)
- Maintainers: See [MAINTAINERS.md](../../MAINTAINERS.md)

---

**Chart Version**: 0.1.0  
**App Version**: 0.4.1  
**Last Updated**: 2025
