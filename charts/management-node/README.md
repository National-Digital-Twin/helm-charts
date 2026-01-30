# management-node Helm Chart

This chart deploys the management-node service as a Kubernetes Deployment exposed through a ClusterIP Service. It packages the container image published to GHCR and provides the common settings for replicas, service account management, and runtime configuration.

## Prerequisites

- Kubernetes 1.25+
- Helm 3.12+
- Access to pull `ghcr.io/national-digital-twin/management-node` images (authenticate to GHCR if required)

## Quick Start

From the root of this repository:

```bash
helm install management-node ./charts/management-node
```

To override the image reference or tag:

```bash
helm install management-node ./charts/management-node \
  --set image.repository=ghcr.io/national-digital-twin/management-node \
  --set image.tag=1.0.1
```

Upgrade in place:

```bash
helm upgrade management-node ./charts/management-node
```

Uninstall:

```bash
helm uninstall management-node
```

## Configuration

| Key | Default | Description |
| --- | --- | --- |
| `replicaCount` | `1` | Number of pods in the deployment. |
| `image.repository` | `ghcr.io/national-digital-twin/management-node` | Container image repository. |
| `image.tag` | `1.0.1` | Container image tag. |
| `image.pullPolicy` | `IfNotPresent` | Image pull policy for the container. |
| `serviceAccount.create` | `true` | Whether to create a dedicated ServiceAccount. |
| `serviceAccount.name` | `""` | Override ServiceAccount name when `create` is false. |
| `service.type` | `ClusterIP` | Kubernetes service type. |
| `service.port` | `8090` | Service port exposed inside the cluster. |
| `app.server.port` | `8090` | HTTPS listener exposed by the Spring application. |
| `app.management.port` | `8081` | Spring Boot actuator management port. |
| `app.javaOpts` | `-Djava.security.egd=...` | Java options injected into `JAVA_OPTS`. |
| `app.ssl.enabled` | `true` | Whether TLS is enabled on the main listener. |
| `app.ssl.clientAuth` | `need` | Client authentication mode for TLS (`need`, `want`, `none`). |
| `app.ssl.keyStore` | `/app/docker/keystore.jks` | Path to the server keystore inside the container. |
| `app.ssl.keyStorePassword` | `null` | Optional keystore password (use secrets in production). |
| `app.ssl.keyStoreType` | `JKS` | Keystore type passed to Spring. |
| `app.ssl.trustStore` | `/app/docker/truststore.jks` | Path to the truststore inside the container. |
| `app.ssl.trustStorePassword` | `null` | Optional truststore password (use secrets in production). |
| `app.ssl.trustStoreType` | `JKS` | Truststore type passed to Spring. |
| `app.datasource.url` | `jdbc:postgresql://localhost:5433/keycloak_db` | JDBC URL for the application datasource. |
| `app.datasource.secret.create` | `false` | Whether the chart should create a Secret containing datasource credentials. |
| `app.datasource.secret.name` | `""` | Secret name (required whether you create a new Secret or reference an existing one). |
| `app.datasource.secret.usernameKey` | `username` | Secret key holding the datasource username. |
| `app.datasource.secret.passwordKey` | `password` | Secret key holding the datasource password. |
| `app.datasource.secret.username` | `null` | Username embedded in a generated Secret (required when `create` is true). |
| `app.datasource.secret.password` | `null` | Password embedded in a generated Secret (required when `create` is true). |
| `app.datasource.secret.annotations` | `{}` | Extra annotations applied to the generated Secret. |
| `app.extraEnv` | `[]` | Additional environment variables appended to the pod. |
| `ingress.enabled` | `false` | Toggle creation of a Kubernetes Ingress resource. |
| `ingress.className` | `""` | Optional `ingressClassName` to target a specific ingress controller. |
| `ingress.annotations` | `{}` | Extra annotations applied to the Ingress metadata. |
| `ingress.hosts` | see values.yaml | List of host/path entries exposed by the Ingress. |
| `ingress.tls` | `[]` | TLS configuration for the Ingress. |
| `resources` | `{}` | Container resource requests/limits. |
| `nodeSelector` | `{}` | Node selector constraints. |
| `tolerations` | `[]` | Pod tolerations. |
| `affinity` | `{}` | Pod affinity rules. |

All values can be overridden with `--set key=value` or by supplying a YAML file via `-f my-values.yaml`.

## Development Notes

- Add an icon field to `Chart.yaml` if you have a suitable asset to remove the Helm lint warning.
- Extend the chart with additional configuration (environment variables, secrets, ingress) as requirements evolve.
