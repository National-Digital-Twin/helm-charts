# README  

**Repository:** `[helm-charts]`  
**Description:** `[This is a repository for storing Helm charts to support deployment of an IA Node.]`  
**SPDX-License-Identifier:** `Apache-2.0 AND OGL-UK-3.0`  

## Overview  

The following repository aims to collate a number of Helm charts to support and ease a first time deployment of the IA Node (Integration Architecture Node). The IA Node is an open-source digital component developed as part of the National Digital Twin Programme (NDTP), to support managing and sharing information across organisations. 

> [!IMPORTANT]
> Secrets management is outside of the scope of the deployment, however we have provided a few possible examples on how you might override the default values, or provide your own where supported.

## Prerequisites  

The following technologies will need to be installed and configured prior to getting started.

Note: Versions highlighted are based on what configurations have been used throughout the testing of the Helm charts. 

- **Supported Kubernetes Versions:** 
  - [`Kubernetes 1.23+`](https://kubernetes.io/): a Kubernetes cluster i.e. AKS or local development cluster 
  
- **Required Tooling:**
  - [`kubectl 1.28.9+`](https://kubernetes.io/docs/reference/kubectl/): prior knowledge, usage and experience with `kubectl` 
  - [`Helm 3.8.0+`](https://helm.sh/): prior knowledge, usage and experience in Helm
  - [`jq 1.6+`](https://jqlang.org/): for querying and formating json
  
- **Optional Tooling:**
  - [`K9s 0.32.5+`](https://K9scli.io/): for Kubernetes cluster overview and visualisation of deployments
  
- **Application Installation Requirements:** 
  - [`Istio Helm chart, Gateway, Base and Istiod 1.25.0+`](https://istio.io/latest/docs/setup/install/helm/): service mesh that layers onto existing application, providing uniform and more efficient ways to secure, connect, and monitor services
  - `OpenID Connect (OIDC) Identity Provider:` the application requires that authentication is performed by the service mesh using an OIDC authentication flow and that all paths exposed on the domain should be authenticated, this install was tested with [`Keycloak`](https://www.keycloak.org/) using [`Bitnami Keycloak Helm chart 24.4.13`](https://github.com/bitnami/charts/blob/main/bitnami/keycloak/README.md) which, also installs [`PostgreSQL`](https://www.postgresql.org/).
  - [`OAuth2Proxy`](https://oauth2-proxy.github.io/oauth2-proxy/): a reverse proxy that should be deployed and integrated with Istio service mesh to provide authentication using a target OpenID Connect (OIDC) Identity Provider, this install used [`Bitnami OAuth2 Proxy Helm chart 6.2.10`](https://github.com/bitnami/charts/blob/main/bitnami/oauth2-proxy/README.md), which also installs [`Redis`](https://redis.io/) a session storage option that can be used with OAuth2Proxy
  - [`MongoDB`](https://www.mongodb.com/): for application data storage, this install was tested with the [`MongoDB Community Operator Helm chart 0.12.0+`](https://www.mongodb.com/try/download/community-kubernetes-operator)
  - [`Apache Kafka`](https://kafka.apache.org/): for application data streaming, this install was tested with the [`Kafka Strimzi Operator 0.45.0+`](https://artifacthub.io/packages/helm/strimzi-kafka-operator/strimzi-kafka-operator)

- **System Requirements:** 
  
  The Helm charts included in this repository were tested against a Kubernetes Cluster with the following specification: 
  - Nodes: 3
  - CPU: 8 vCores 
  - Memory: 32 GB 
  - Storage: 64 GB

---

## Quick Start  

Follow these steps to get started with the charts in this repository. 

> [!TIP]
> Replace references to `localhost` with your desired installation domain and `localhost-oidc` with your own OIDC provider. 

### 1. Base Platform Setup

#### Kubernetes Cluster

Follow any official documentation to deploy a desired install i.e. [Azure AKS](https://learn.microsoft.com/en-us/azure/aks/what-is-aks), [Amazon EKS](https://docs.aws.amazon.com/eks/latest/userguide/what-is-eks.html), or to run a quick install or testing setup, configure a local development cluster i.e. [minikube](https://kubernetes.io/docs/tutorials/hello-minikube/), [k3s](https://k3s.io/), [microk8s](https://microk8s.io/).

#### Install Helm

Helm is a tool that can be used to package a set of pre-configured Kubernetes resources. To install, refer to the [Helm install guide](https://helm.sh/docs/intro/install/) and [quick start](https://helm.sh/docs/intro/quickstart/). 

### Install Istio 

Any Istio examples throughout this documentation are provided largely as information, to help support integrators to plan their own deployment. 

> [!IMPORTANT]
The installation assumes that Istio has already been installed Istio, following the [Istio Helm Install](https://istio.io/latest/docs/setup/install/helm/) guide, and assumes a default principal of `cluster.local/ns/istio-system/sa/ingressgateway`, and default gateway of `istio-system/istio-gateway`. You will require a [gateway](https://istio.io/latest/docs/reference/config/networking/gateway/) and a domain, listening on HTTPS port (443), presenting a valid TLS certificate. Istio should be integrated with an OIDC conformant Identity Provider (IdP) e.g. Keycloak, Cognito etc. It is required that the IdP be configured with users, clients and groups. The application requires the authentication to be performed by the service mesh using an OIDC authentication flow, which can be done by configuring the Istio options: [global mesh config](https://istio.io/latest/docs/reference/config/istio.mesh.v1alpha1/), or an [Envoy Filter](https://istio.io/latest/docs/reference/config/networking/envoy-filter/). All paths exposed on the domain should be authenticated. 

> [!NOTE]
> Istio `authorization policies` are implemented to restrict communications between components. These principals are based on the namespace a service is deployed to and the service account it runs as. In particular, the principal that the Istio ingress is assigned, is environment specific and may differ from the one specified in the default deployment. These can all be overridden using the Helm values. 

#### Create Namespace 

Most of the deployment assumes you have a namespace configured as follows:

```sh
kubectl create namespace ia-node
kubectl label namespace ia-node istio-injection=enabled
```

### 2. Install ia-node-oidc, OIDC Provider and OAuth2Proxy with Redis

#### Install Keycloak

> [!NOTE]  
> This section assumes Istio is installed, and configured with a gateway and mesh config or envoy filter to handle the redirection of OAuth2 Proxy.

The following creates a namespace called Keycloak, labels it to ensure Istio envoys are deployed with Keycloak, and deploys Keycloak via its Helm chart.

```sh
kubectl create namespace keycloak
kubectl label namespace keycloak istio-injection=enabled
helm install keycloak oci://registry-1.docker.io/bitnamicharts/keycloak -n keycloak 
```
You will need to create a virtual service and configure a realm. 

> [!NOTE]  
> Note: The example realm [keycloak-realm.json](./config/keycloak-realm.json), can be imported as a reference/starting point. This example includes example clients and a group client scope thgat maps both group membership and realm roles mappers, however only one of these options are required. 


### Install ia-node-oidc, OAuth2Proxy and Redis 

> [!NOTE]  
> This section assumes Istio is installed, and configured with a gateway and mesh config or envoy filter to handle the redirection of OAuth2 Proxy. In addition it assumes, Keycloak has been deployed on the cluster ie. `http://keycloak.keycloak.svc.cluster.local` with a realm, test users, client and some groups configured. The Keycloak values are configurable if you are using an external install. 

Deploy the [ia-node-oidc](./charts/ia-node-oidc/README.md) helper chart to help with setting up an OIDC conformant Identity Provider (IdP) to work with the IA Node setup.

```sh
helm install ia-node-oidc oci://ghcr.io/national-digital-twin/helm/ia-node-oidc -n ia-node --set oidcProvider.configMap.redirect_url="https://localhost/oauth2/callback" 
```
A config map and optional secret output is generated by the package, that can then be used to override the OAuth2 Proxy installation. 

Deploy OAuth2Proxy (with Redis) with Helm: 
```sh
helm install oauth2-proxy oci://registry-1.docker.io/bitnamicharts/oauth2-proxy -n ia-node --set configuration.existingSecret="oauth2-proxy-default" --set configuration.existingConfigmap="oauth2-proxy-default" --set istio.virtualService.hosts[0]="localhost"
```

### 3. Install ia-node-mongodb to deploy a MongoDB

> [!NOTE]  
> This section assumes Istio is installed, and configured with a gateway and mesh config or envoy filter to handle the redirection of OAuth2 Proxy. 

Deploy the MongoDB community operator with Helm:

```sh
helm repo add mongodb https://mongodb.github.io/helm-charts
helm install community-operator mongodb/community-operator --namespace mongodb-operator --create-namespace --set operator.watchNamespace="*"
```

Deploy the [ia-node-mongodb](./charts/ia-node-mongodb/README.md) helper chart to deploy a MongoDB instance:

```sh
helm install ia-node-mongodb oci://ghcr.io/national-digital-twin/helm/ia-node-mongodb -n ia-node 
```

### 4. Install ia-node-kafka to deploy Apache Kafka

> [!NOTE]  
> This section assumes Istio is installed, and configured, with a gateway and mesh config or envoy filter to handle the redirection of OAuth2 Proxy. 

Deploy the Kafka operator with Helm:
```sh
helm install my-strimzi-cluster-operator oci://quay.io/strimzi-helm/strimzi-kafka-operator  --namespace kafka-operator --create-namespace --set watchAnyNamespace="true"
```

Deploy the [ia-node-kafka](./charts/ia-node-kafka/README.md) helper chart for use specifically with the integration architecture node (IA Node secure graph component).

```sh
helm install ia-node-kafka oci://ghcr.io/national-digital-twin/helm/ia-node-kafka  -n ia-node 
```

### 5. Install IA Node to deploy the IA Node Applications

> [!NOTE]  
> This section assumes Istio is installed, and configured with a gateway and mesh config or envoy filter to handle the redirection of OAuth2 Proxy and that this is now integrated with an identity provider. In addition it assumes, MongoDB and Kafka have been deployed on the cluster i.e. `mongodb-svc:27017` and `kafka-cluster-kafka-bootstrap:9093` respectively, are using secret names of `ia-node-user-password` and `kafka-auth-config` respectively. These can all be overridden in the values as required, along with any other requirements if you are hosting these services externally. 

```sh
helm install ia-node oci://ghcr.io/national-digital-twin/helm/ia-node -n ia-node \
--set apps.api.configMap.data.DEPLOYED_DOMAIN="http://localhost" \
--set apps.api.configMap.data.OPENID_PROVIDER_URL="http://keycloak.keycloak.svc.cluster.local/realms/ianode/" \
--set apps.graph.configMap.data.JWKS_URL="http://keycloak.keycloak.svc.cluster.local/realms/ianode/.well-known/openid-configuration" \
--set istio.virtualService.hosts[0]="localhost"
```

## Full Installation and Configuration

The full configuration and installation can be found in each individual chart in the corresponding `README.md` files. 

- [`ia-node-oidc README.md`](./charts/ia-node-oidc/README.md)
- [`ia-node-mongodb README.md`](./charts/ia-node-mongodb/README.md)
- [`ia-node-kafka README.md`](./charts/ia-node-kafka/README.md)
- [`ia-node README.md`](./charts/ia-node/README.md)

## Uninstall 

Uninstall in reverse order, i.e.

```sh
helm uninstall ia-node -n ia-node 
```

```sh
helm uninstall ia-node-kafka -n ia-node
helm uninstall my-strimzi-cluster-operator -n kafka-operator
```

```sh
helm uninstall ia-node-mongodb -n ia-node 
helm uninstall community-operator -n mongodb-operator 
```

```sh
helm uninstall oauth2-proxy -n ia-node
helm uninstall ia-node-oidc -n ia-node
```

```sh
helm uninstall keycloak -n keycloak
```

Uninstall namespaces:
```sh
kubectl delete ns ia-node ia-node-kafka kafka-operator keycloak mongodb-operator
```

## Features

This repository contains several Helm charts to support deployment of an IA Node. 

- **Core functionality** 
  - [`ia-node`](./charts/ia-node/README.md): Helm chart to deploy the IA Node application components.

- **Supportive functionality** 
  - [`ia-node-oidc`](./charts/ia-node-oidc/README.md): Helm chart intended to ease deployment and configuration of an OIDC conformant Identity Provider (IdP) Keycloak integrated with Istio, OAuth2 Proxy and Redis, which are prerequisites required to deploy an IA Node.
  -  [`ia-node-mongodb`](./charts/ia-node-mongodb/README.md): Helm chart intended to ease deployment and configuration of MongoDB which is a prerequisite required to deploy an IA Node.
  -  [`ia-node-kafka`](./charts/ia-node-kafka/README.md): Helm chart intended to ease deployment and configuration of Apache Kafka which is a prerequisite required to deploy an IA Node.

---

## Public Funding Acknowledgment  
This repository has been developed with public funding as part of the National Digital Twin Programme (NDTP), a UK Government initiative. NDTP, alongside its partners, has invested in this work to advance open, secure, and reusable digital twin technologies for any organisation, whether from the public or private sector, irrespective of size.  

## License  
This repository contains both source code and documentation, which are covered by different licenses:  
- **Code:** Developed and maintained by **National Digital Twin Programme**. Licensed under the [Apache License 2.0](./LICENSE.md).  
- **Documentation:** Licensed under the [Open Government Licence v3.0](./OGL_LICENSE.md).  
See [`LICENSE.md`](./LICENSE.md), [`OGL_LICENSE.md`](./OGL_LICENSE.md), and [`NOTICE.md`](./NOTICE.md) for details.  

## Security and Responsible Disclosure  
We take security seriously. If you believe you have found a security vulnerability in this repository, please follow our responsible disclosure process outlined in [`SECURITY.md`](./SECURITY.md).  

## Contributing  
We welcome contributions that align with the Programme’s objectives. Please read our [`CONTRIBUTING.md`](./CONTRIBUTING.md) guidelines before submitting pull requests.  

## Acknowledgements  
This repository has benefited from collaboration with various organisations. For a list of acknowledgments, see [`ACKNOWLEDGEMENTS.md`](./ACKNOWLEDGEMENTS.md).  

## Support and Contact  
For questions or support, check our Issues or contact the NDTP team on ndtp@businessandtrade.gov.uk.

**Maintained by the National Digital Twin Programme (NDTP).**  

© Crown Copyright 2025. This work has been developed by the National Digital Twin Programme and is legally attributed to the Department for Business and Trade (UK) as the governing entity.
