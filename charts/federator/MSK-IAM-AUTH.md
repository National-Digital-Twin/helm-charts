# AWS MSK IAM Authentication

This Helm chart includes built-in support for AWS MSK (Managed Streaming for Apache Kafka) IAM authentication.

## Overview

When connecting to AWS MSK with IAM authentication, the Federator requires the AWS MSK IAM authentication library to be present on the classpath. This chart automates the process of downloading and mounting this library.

## How It Works

When `mskIamAuth.enabled` is set to `true`, the chart will:

1. Create an init container that downloads the AWS MSK IAM authentication JAR file
2. Mount the library into the main container at `/library`
3. The Federator startup command automatically includes `/library/*` in the Java classpath

## Configuration

### Basic Usage

To enable AWS MSK IAM authentication, add this to your values file:

```yaml
mskIamAuth:
  enabled: true
```

### Full Configuration Options

```yaml
mskIamAuth:
  enabled: true
  image: curlimages/curl:8.11.1
  downloadUrl: "https://github.com/aws/aws-msk-iam-auth/releases/download/v2.3.0/aws-msk-iam-auth-2.3.0-all.jar"
  jarFileName: "aws-msk-iam-auth-2.3.0-all.jar"
  libraryPath: "/library"
  volumeName: "msk-lib"
```

### Using a Private Container Registry

If you're deploying in an air-gapped environment or using a private registry:

```yaml
mskIamAuth:
  enabled: true
  image: your-registry.example.com/docker-hub/curlimages/curl:8.11.1
```

### AWS Region Configuration

Don't forget to set the AWS region as an environment variable:

```yaml
extraEnv:
  - name: AWS_REGION
    value: eu-west-2
```

### Kafka Properties Configuration

In your `client.properties` or `server.properties`, configure Kafka to use AWS MSK IAM:

```properties
kafka.additional.security.protocol=SASL_SSL
kafka.additional.sasl.mechanism=AWS_MSK_IAM
kafka.additional.sasl.jaas.config=software.amazon.msk.auth.iam.IAMLoginModule required;
kafka.additional.sasl.client.callback.handler.class=software.amazon.msk.auth.iam.IAMClientCallbackHandler
```

### IAM Role Configuration

The Federator pod needs an IAM role with permissions to access MSK. Configure this via service account annotations:

```yaml
serviceAccount:
  create: true
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/your-msk-access-role
```

## Complete Example

See `examples/values-client-example.yaml` for a complete working example that includes:
- MSK IAM authentication enabled
- Kafka configuration for AWS MSK
- Service account with IAM role
- Redis configuration
- All required properties

## Troubleshooting

### Init Container Fails to Download Library

If the init container fails with a connection error:

1. Check if your cluster has internet access
2. Verify the download URL is correct
3. Consider hosting the JAR file internally and updating `downloadUrl`

### ClassNotFoundException for IAMClientCallbackHandler

If you see this error in the logs:
```
Class software.amazon.msk.auth.iam.IAMClientCallbackHandler could not be found
```

This means the MSK IAM library is not in the classpath. Verify:
1. `mskIamAuth.enabled` is set to `true`
2. The init container ran successfully (check pod events)
3. The library file exists: `kubectl exec <pod> -- ls -la /library/`

### NOAUTH Authentication Required (Redis)

This is unrelated to MSK authentication. If you see Redis NOAUTH errors, you need to either:
1. Configure Redis credentials in your properties file
2. Use a Redis instance without authentication
3. See the main README for Redis configuration options

## Version Compatibility

- Chart version: 0.1.1+
- Federator version: 0.90.0+
- AWS MSK IAM Auth library: v2.3.0
- Tested with: AWS MSK, Amazon EKS

## References

- [AWS MSK IAM Authentication](https://github.com/aws/aws-msk-iam-auth)
- [AWS MSK Documentation](https://docs.aws.amazon.com/msk/latest/developerguide/iam-access-control.html)
- [Federator Documentation](../../../README.md)
