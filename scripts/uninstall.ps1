## For use just with Local Deployment or Development
## Assumes you already have Istio setup and Key Cloak configured. 

$RemoveOperators=$false

helm uninstall ia-node-oidc -n ia-node 

helm uninstall oauth2-proxy -n ia-node 

helm uninstall ia-node-mongodb -n ia-node 
if($RemoveOperators) { helm uninstall community-operator -n mongodb-operator }
if($RemoveOperators) { helm repo remove mongodb } 

helm uninstall ia-node-kafka -n ia-node 
if($RemoveOperators) { helm uninstall my-strimzi-cluster-operator -n kafka-operator } 

helm uninstall ia-node -n ia-node 

kubectl delete ns ia-node 
if($RemoveOperators) { kubectl delete ns mongodb-operator kafka-operator }