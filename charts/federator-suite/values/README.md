# Values Files Guide

## Structure

```
values/
├── common-values.yaml          # Base config (all environments)
├── kafka.yaml                  # Kafka defaults
├── valkey.yaml                 # Valkey defaults
├── federator.yaml              # Application defaults
├── ui.yaml                     # Monitoring UIs
├── dry-run.yaml                # CI/CD testing (no secrets)
└── overrides/
    ├── local/                  # Local Kind cluster
    │   ├── local.yaml         # Shared Kind settings
    │   ├── bcc.yaml           # BCC org config
    │   ├── env.yaml           # ENV org config
    │   ├── heg.yaml           # HEG org config
    │   └── secrets.yaml       # All local secrets
    ├── dev/                    # Dev deployments
    │   ├── bcc.yaml           # BCC: AWS EKS + org config
    │   ├── env.yaml           # ENV: AWS EKS + org config
    │   ├── heg.yaml           # HEG: Azure AKS + org config
    │   └── secrets/
    │       ├── bcc-secrets.yaml
    │       ├── env-secrets.yaml
    │       └── heg-secrets.yaml
    └── prod/
        └── secrets/
```

## Design

**Component files** = Reusable defaults (kafka.yaml, valkey.yaml, etc.)  
**Override files** = Environment + Org in ONE file

**Note:** Kafka uses Strimzi Operator CRDs (operator installed separately)

Each org's override file contains:
- Cloud settings (ECR/ACR, MSK/EventHubs, LoadBalancer annotations)
- Org settings (prefixes, topics, namespaces)
- Self-contained: No need to combine multiple files per deployment

## Usage

### Local (Multi-Org Testing)

```bash
# Deploy BCC to Kind
helm install bcc . -n ia-federation \
  -f values/common-values.yaml \
  -f values/kafka.yaml \
  -f values/valkey.yaml \
  -f values/federator.yaml \
  -f values/ui.yaml \
  -f values/overrides/local/local.yaml \
  -f values/overrides/local/bcc.yaml \
  -f values/overrides/local/secrets.yaml

# Or use Makefile
make deploy-local ORG=bcc
make deploy-local ORG=env
make deploy-local ORG=heg
```

### Dev/Prod (Real Deployments)

```bash
# Deploy BCC to AWS dev
helm install bcc . -n ia-federation \
  -f values/common-values.yaml \
  -f values/kafka.yaml \
  -f values/valkey.yaml \
  -f values/federator.yaml \
  -f values/ui.yaml \
  -f values/overrides/dev/bcc.yaml \
  -f values/overrides/dev/secrets/bcc-secrets.yaml

# Or use Makefile
make deploy ENV=dev ORG=bcc
make deploy ENV=dev ORG=env
make deploy ENV=dev ORG=heg
```

## File Contents

**common-values.yaml**: Global defaults, default resource requests  
**Component files**: Subchart values, shared configuration  
**overrides/local/local.yaml**: Kind cluster settings (NodePort, local images, in-cluster Kafka/Valkey)  
**overrides/local/{org}.yaml**: Org-specific (namespace, prefixes, NodePort numbers)  
**overrides/dev/{org}.yaml**: Complete cloud + org config (ECR, MSK, Istio, prefixes, topics)  
**secrets files**: Certificates, passwords, access maps (not in git)

## Precedence (Last Wins)

```
1. common-values.yaml
2. kafka.yaml, valkey.yaml, federator.yaml, ui.yaml
3. overrides/{env}/{org}.yaml (or local.yaml + org.yaml for local)
4. secrets file (highest priority)
```

## Adding New Organization

```bash
# Copy existing org config
cp values/overrides/dev/bcc.yaml values/overrides/dev/neworg.yaml

# Edit cloud and org settings
# - Image repositories (ECR/ACR)
# - Kafka endpoints (MSK/EventHubs)
# - Org prefixes, topics, namespaces

# Create secrets
cp values/secrets.yaml.example values/overrides/dev/secrets/neworg-secrets.yaml
# Fill in certificates and passwords

# Deploy
make deploy ENV=dev ORG=neworg
```

## Namespaces

- **Local**: Created automatically by Makefile
- **Dev/Prod**: Must already exist in cluster
- **Auto-detected**: Makefile reads namespace from override files
- **Override**: `make deploy ENV=dev ORG=bcc NAMESPACE=custom`

## Security

- All `*-secrets.yaml` files are in `.gitignore`
- Use `secrets.yaml.example` as template
- Store production secrets in vault (AWS Secrets Manager, Azure Key Vault)
