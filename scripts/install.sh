#!/bin/bash
## For use just with Local Deployment or Development. Assumes you already have Istio setup and Key Cloak configured. 

APPLICATION_DOMAIN="http://localhost"
NAMESPACE="ia-node"
INSTALL_TYPE="local_dev" 
INSTALL_OPERATORS="false"
 
case $INSTALL_TYPE in
    "local_dev")
        Directory="./helm-charts/charts"
        ;;
    "test_package")
        Directory="oci://ghcr.io/national-digital-twin/helm-test"
        ;;
    *)
        Directory="oci://ghcr.io/national-digital-twin/helm"
        ;;
esac

kubectl create namespace $(echo $NAMESPACE)
kubectl label namespace $(echo $NAMESPACE) istio-injection=enabled

helm install ia-node-oidc $(echo "${Directory}/ia-node-oidc") -n $(echo $NAMESPACE) --wait \
    --set oidcProvider.configMap.redirect_url=$(echo "${APPLICATION_DOMAIN}/oauth2/callback") 
  
helm install oauth2-proxy oci://registry-1.docker.io/bitnamicharts/oauth2-proxy -n $(echo $NAMESPACE) --wait \
    --set configuration.existingSecret="oauth2-proxy-default" \
    --set configuration.existingConfigmap="oauth2-proxy-default" 

if [ $(echo "$INSTALL_OPERATORS") = "true" ]; then
    helm repo add mongodb https://mongodb.github.io/helm-charts
    helm install community-operator mongodb/community-operator --namespace mongodb-operator --create-namespace --set operator.watchNAMESPACE="*" --wait
    helm install my-strimzi-cluster-operator oci://quay.io/strimzi-helm/strimzi-kafka-operator  --namespace kafka-operator --create-namespace --set watchAnyNamespace="true"
fi

helm install ia-node-mongodb $(echo "${Directory}/ia-node-mongodb") -n $(echo $NAMESPACE) --wait 

helm install ia-node-kafka $(echo "${Directory}/ia-node-kafka") -n $(echo $NAMESPACE) --wait 

helm install ia-node $(echo "${Directory}/ia-node") -n $(echo $NAMESPACE) --wait \
    --set apps.api.configMap.data.DEPLOYED_DOMAIN=$(echo "${APPLICATION_DOMAIN}") 