# test-message-pod Helm Chart

A simple Helm chart for deploying a test pod to send messages to Kafka for federation testing.

## Prerequisites

- Kubernetes cluster with Kafka deployed
- Kafka authentication configured (SASL or IAM)
- kubectl configured to access the cluster

## Quick Start

### Option 1: Use Pre-built Image (AWS ECR)

```bash
helm install test-msg charts/test-message-pod -n org-a \
  --set kafka.bootstrapServer=kafka-cluster-kafka-bootstrap.org-a.svc.cluster.local:9092 \
  --set kafka.topic=knowledge \
  --set kafka.securityProtocol=SASL_PLAINTEXT \
  --set kafkaCredentialsSecret.name=kafka-auth-config
```

### Option 2: Build and Use Local Image

1. Build the Docker image (from the chart directory):
```bash
cd helm-charts/charts/test-message-pod
docker build -t test-message-pod:local .
```

2. For Kind clusters, load the image:
```bash
kind load docker-image test-message-pod:local --name kind
```

3. Install the chart with local values:
```bash
cd ../..  # back to helm-charts root
helm install test-msg charts/test-message-pod -n org-a \
  -f charts/test-message-pod/values-local.yaml
```

Or use command-line overrides:
```bash
helm install test-msg charts/test-message-pod -n org-a \
  --set image.repository=test-message-pod \
  --set image.tag=local \
  --set image.pullPolicy=Never \
  --set kafka.bootstrapServer=kafka-cluster-kafka-bootstrap.org-a.svc.cluster.local:9092 \
  --set kafka.securityProtocol=SASL_PLAINTEXT \
  --set kafkaCredentialsSecret.name=kafka-auth-config
```

## Sending Test Messages

Once deployed, exec into the pod and send messages:

```bash
# Send the included test data file
kubectl exec -n org-a test-msg-test-message-pod -- /opt/scripts/send-kafka-message.sh /tmp/test-data.trig

# Or create a custom test message
kubectl exec -n org-a test-msg-test-message-pod -- bash -c 'cat > /tmp/custom-data.trig << EOF
@prefix ex: <http://example.org/> .
ex:subject ex:predicate "Test message" .
EOF'

# Send the custom message
kubectl exec -n org-a test-msg-test-message-pod -- /opt/scripts/send-kafka-message.sh /tmp/custom-data.trig
```

## Configuration

### Key Values

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.repository` | Image repository | `Idhere.dkr.ecr.eu-west-2.amazonaws.com/curl-kafka-tools` |
| `image.tag` | Image tag | `latest` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `kafka.bootstrapServer` | Kafka bootstrap server | `kafka-cluster-kafka-bootstrap:9092` |
| `kafka.topic` | Default Kafka topic | `knowledge` |
| `kafka.securityProtocol` | Security protocol (SASL_PLAINTEXT, SASL_SSL) | `SASL_PLAINTEXT` |
| `kafka.saslMechanism` | SASL mechanism (SCRAM-SHA-512, AWS_MSK_IAM) | `SCRAM-SHA-512` |
| `kafkaCredentialsSecret.name` | Name of secret containing Kafka credentials | `kafka-auth-config` |
| `kafkaCredentialsSecret.enabled` | Mount Kafka credentials secret | `true` |
| `message.headers.contentType` | Default Content-Type header | `application/trig` |
| `message.headers.securityLabel` | Default Security-Label header | `dataset=CarModels-Knowledge,...` |

### Example: AWS MSK with IAM Authentication

```bash
helm install test-msg charts/test-message-pod -n org-a \
  --set kafka.bootstrapServer=b-1.mycluster.kafka.eu-west-2.amazonaws.com:9098 \
  --set kafka.securityProtocol=SASL_SSL \
  --set kafka.saslMechanism=AWS_MSK_IAM \
  --set kafkaCredentialsSecret.enabled=false \
  --set serviceAccount.name=kafka-access-sa
```

## Uninstall

```bash
helm uninstall test-msg -n org-a
```

## Development

To modify the send-kafka-message.sh script, edit `templates/configmap.yaml`. The script is automatically mounted to `/opt/scripts/` in the pod.

Environment variables available in the pod:
- `KAFKA_BOOTSTRAP_SERVER`
- `KAFKA_TOPIC`
- `KAFKA_SECURITY_PROTOCOL`
- `KAFKA_SASL_MECHANISM`
- `MESSAGE_CONTENT_TYPE`
- `MESSAGE_SECURITY_LABEL`
