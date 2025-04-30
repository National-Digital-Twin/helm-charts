## For use just with Local Deployment or Development. 
## Assumes you already have Key Cloak configured. 

$ApplicationDomain="http://localhost"
$Namespace="ia-node"
$InstallType="local_dev" 
$InstallOperators=$false

switch ($InstallType) {
    "local_dev"     {$Directory="./helm-charts/charts" } ## for developing the and editing the charts
    "test_package"  {$Directory="oci://ghcr.io/national-digital-twin/helm-test"} ## for deployment with the test packages
    default         {$Directory="oci://ghcr.io/national-digital-twin/helm"} ## for default deployment using the live public packages
 }

kubectl create namespace $Namespace
kubectl label namespace $Namespace istio-injection=enabled

helm install ia-node-oidc $Directory/ia-node-oidc -n $Namespace --wait `
    --set oidcProvider.configMap.redirect_url="${ApplicationDomain}/oauth2/callback"  

helm install oauth2-proxy oci://registry-1.docker.io/bitnamicharts/oauth2-proxy -n $Namespace --wait `
    --set configuration.existingSecret="oauth2-proxy-default" `
    --set configuration.existingConfigmap="oauth2-proxy-default" 

if($InstallOperators) { helm repo add mongodb https://mongodb.github.io/helm-charts }
if($InstallOperators) { helm install community-operator mongodb/community-operator --namespace mongodb-operator --create-namespace --set operator.watchNamespace="*" --wait }

helm install ia-node-mongodb $Directory/ia-node-mongodb -n $Namespace --wait 

if($InstallOperators) { helm install my-strimzi-cluster-operator oci://quay.io/strimzi-helm/strimzi-kafka-operator  --namespace kafka-operator --create-namespace --set watchAnyNamespace="true" }
helm install ia-node-kafka $Directory/ia-node-kafka -n $Namespace --set kafkaCluster.connectEnabled=true --wait 

helm install ia-node $Directory/ia-node -n $Namespace --wait --set apps.api.configMap.data.DEPLOYED_DOMAIN="${ApplicationDomain}" 