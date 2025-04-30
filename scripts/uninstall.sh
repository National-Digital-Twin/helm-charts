#!/bin/bash
## For use just with Local Deployment or Development. Assumes you already have Istio setup and Key Cloak configured. 

REMOVE_OPERATORS="false"

helm uninstall ia-node-oidc -n ia-node 

helm uninstall oauth2-proxy -n ia-node 

helm uninstall ia-node-mongodb -n ia-node 

helm uninstall ia-node-kafka -n ia-node 

helm uninstall ia-node -n ia-node 

kubectl delete ns ia-node 

 if [ $(echo "$REMOVE_OPERATORS") = "true" ]; then
    helm uninstall community-operator -n mongodb-operator
    helm repo remove mongodb
    helm uninstall my-strimzi-cluster-operator -n kafka-operator
    kubectl delete ns mongodb-operator kafka-operator
fi