{{/*
Expand the name of the chart.
*/}}
{{- define "federator-suite.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Determine if Kafka subchart should be enabled (inverse of external flag)
*/}}
{{- define "federator-suite.kafka.enabled" -}}
{{- not .Values.kafka.external }}
{{- end }}

{{/*
Determine if Valkey subchart should be enabled (inverse of external flag)
*/}}
{{- define "federator-suite.valkey.enabled" -}}
{{- not .Values.valkey.external }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "federator-suite.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "federator-suite.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "federator-suite.labels" -}}
helm.sh/chart: {{ include "federator-suite.chart" . }}
{{ include "federator-suite.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "federator-suite.selectorLabels" -}}
app.kubernetes.io/name: {{ include "federator-suite.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Federator Server labels
*/}}
{{- define "federator-suite.server.labels" -}}
helm.sh/chart: {{ include "federator-suite.chart" . }}
app: federator-server
{{ include "federator-suite.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/component: server
{{- end }}

{{/*
Federator Client labels
*/}}
{{- define "federator-suite.client.labels" -}}
helm.sh/chart: {{ include "federator-suite.chart" . }}
app: federator-client
{{ include "federator-suite.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/component: client
{{- end }}

{{/*
Service account name for server
*/}}
{{- define "federator-suite.server.serviceAccountName" -}}
{{- if .Values.federatorServer.serviceAccount.create }}
{{- default (printf "%s-federator-server" .Release.Name) .Values.federatorServer.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.federatorServer.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Service account name for client
*/}}
{{- define "federator-suite.client.serviceAccountName" -}}
{{- if .Values.federatorClient.serviceAccount.create }}
{{- default (printf "%s-federator-client" .Release.Name) .Values.federatorClient.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.federatorClient.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Server full name (with release prefix for multi-org)
*/}}
{{- define "federator-suite.server.fullname" -}}
{{- printf "%s-federator-server" .Release.Name }}
{{- end }}

{{/*
Client full name (with release prefix for multi-org)
*/}}
{{- define "federator-suite.client.fullname" -}}
{{- printf "%s-federator-client" .Release.Name }}
{{- end }}

{{/*
Generic resource name helper (with release prefix)
*/}}
{{- define "federator-suite.resourceName" -}}
{{- $name := . }}
{{- printf "%s-%s" $.Release.Name $name }}
{{- end }}

{{/*
Kafka bootstrap servers
Returns the appropriate Kafka bootstrap servers based on external flag
Strimzi creates service: <cluster-name>-kafka-bootstrap
*/}}
{{- define "federator-suite.kafka.bootstrapServers" -}}
{{- if .Values.kafka.external }}
{{- .Values.kafka.externalConfig.bootstrapServers }}
{{- else }}
{{- printf "%s-kafka:9092" .Release.Name }}
{{- end }}
{{- end }}

{{/*
Kafka security protocol
*/}}
{{- define "federator-suite.kafka.securityProtocol" -}}
{{- if .Values.kafka.external }}
{{- .Values.kafka.externalConfig.securityProtocol }}
{{- else }}
{{- if .Values.kafka.listeners }}
{{- .Values.kafka.listeners.client.protocol | default "SASL_PLAINTEXT" }}
{{- else }}
SASL_PLAINTEXT
{{- end }}
{{- end }}
{{- end }}

{{/*
Kafka SASL mechanism
*/}}
{{- define "federator-suite.kafka.saslMechanism" -}}
{{- if .Values.kafka.external -}}
{{- .Values.kafka.externalConfig.saslMechanism -}}
{{- else -}}
SCRAM-SHA-512
{{- end -}}
{{- end -}}

{{/*
Valkey host
*/}}
{{- define "federator-suite.valkey.host" -}}
{{- if .Values.valkey.external }}
{{- .Values.valkey.externalConfig.host }}
{{- else }}
{{- printf "%s-valkey-primary" .Release.Name }}
{{- end }}
{{- end }}

{{/*
Valkey port
*/}}
{{- define "federator-suite.valkey.port" -}}
{{- if .Values.valkey.external }}
{{- .Values.valkey.externalConfig.port | default 6379 }}
{{- else }}
{{- .Values.valkey.valkey.master.service.port | default 6379 }}
{{- end }}
{{- end }}

{{/*
Valkey password (from secret or plain value)
*/}}
{{- define "federator-suite.valkey.password" -}}
{{- if .Values.valkey.external }}
{{- if .Values.valkey.externalConfig.auth.enabled }}
{{- .Values.valkey.externalConfig.auth.token }}
{{- else }}
{{- "" }}
{{- end }}
{{- else }}
{{- if .Values.valkey.valkey.auth.enabled }}
{{- .Values.valkey.valkey.auth.password }}
{{- else }}
{{- "" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Validate configuration - basic checks
*/}}
{{- define "federator-suite.validateConfig" -}}
{{- if and .Values.kafka.external (not .Values.kafka.externalConfig.bootstrapServers) }}
{{- fail "ERROR: kafka.external is true but kafka.externalConfig.bootstrapServers is not set" }}
{{- end }}
{{- if and .Values.valkey.external (not .Values.valkey.externalConfig.host) }}
{{- fail "ERROR: valkey.external is true but valkey.externalConfig.host is not set" }}
{{- end }}
{{- /* Certificate validation disabled for templating - secrets should be provided at deployment time */ -}}
{{- if .Values.istio.enabled }}
{{- if and (not .Values.istio.gateway.enabled) (not .Values.istio.virtualService.enabled) }}
{{- fail "ERROR: istio.enabled is true but no Istio resources are enabled (gateway, virtualService)" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Image pull policy helper
*/}}
{{- define "federator-suite.imagePullPolicy" -}}
{{- if eq .Values.global.environment "local" }}
{{- "Never" }}
{{- else }}
{{- "IfNotPresent" }}
{{- end }}
{{- end }}

{{/*
Istio sidecar annotation
*/}}
{{- define "federator-suite.istio.inject" -}}
{{- if .Values.serviceMesh.istio.enabled }}
sidecar.istio.io/inject: "true"
{{- else }}
sidecar.istio.io/inject: "false"
{{- end }}
{{- end }}

{{/*
Generate org prefix for topic names
*/}}
{{- define "federator-suite.orgPrefix" -}}
{{- if .Values.global.orgPrefix }}
{{- .Values.global.orgPrefix }}
{{- else }}
{{- .Values.global.orgName | lower }}
{{- end }}
{{- end }}

{{/*
Kafka topic prefix (for Deprecated topics)
*/}}
{{- define "federator-suite.kafkaTopicPrefix" -}}
{{- if .Values.federatorServer.config.kafkaTopicPrefix }}
{{- .Values.federatorServer.config.kafkaTopicPrefix }}
{{- else }}
{{- printf "Deprecated%s" (.Values.global.orgName | upper) }}
{{- end }}
{{- end }}

{{/*
Client properties file content
*/}}
{{- define "federator-suite.clientProperties" -}}
# Kafka Configuration (Sender)
kafka.sender.defaultKeySerializerClass=org.apache.kafka.common.serialization.BytesSerializer
kafka.sender.defaultValueSerializerClass=org.apache.kafka.common.serialization.BytesSerializer

# Kafka Bootstrap Servers
kafka.bootstrapServers={{ include "federator-suite.kafka.bootstrapServers" . }}
{{- if or .Values.kafka.external (and (not .Values.kafka.external) .Values.kafka.sasl) }}
kafka.additional.security.protocol={{ include "federator-suite.kafka.securityProtocol" . }}
kafka.additional.sasl.mechanism={{ include "federator-suite.kafka.saslMechanism" . }}
kafka.additional.sasl.jaas.config={{ .Values.secrets.kafkaAuth.jaasConfig }}
{{- end }}

# Topic Configuration
kafka.topic.prefix={{ include "federator-suite.kafkaTopicPrefix" . }}
kafka.consumerGroup={{ .Values.federatorClient.config.consumerGroup | default (printf "ndtp.dbt.gov.uk.%s" (.Values.global.orgName | lower)) }}

# Redis/Valkey Configuration
{{- $password := include "federator-suite.valkey.password" . -}}
{{- $redisTlsEnabled := false -}}
{{- if .Values.valkey.external }}
{{- if kindIs "bool" .Values.valkey.external }}
{{- $redisTlsEnabled = true }}
{{- else if .Values.valkey.external.enabled }}
{{- $redisTlsEnabled = true }}
{{- end }}
{{- else if and .Values.valkey.enabled .Values.valkey.valkey.master.tls }}
{{- $redisTlsEnabled = .Values.valkey.valkey.master.tls.enabled }}
{{- end }}
redis.host={{ include "federator-suite.valkey.host" . }}
redis.port={{ include "federator-suite.valkey.port" . }}
redis.tls.enabled={{ ternary "true" "false" $redisTlsEnabled }}
redis.prefix={{ .Values.federatorClient.config.redisPrefix | default (printf "federator-client-%s" (.Values.global.orgName | lower)) }}
{{- if $password }}
redis.username=
redis.password={{ $password }}
redis.aes.key=
{{- else }}
redis.username=
redis.password=
redis.aes.key=
{{- end }}

# Common Configuration
common.configuration=/common-configuration/common-configuration.properties

# JobRunr Configuration
org.jobrunr.jobs.default-allow-concurrent-execution=false
jobs.dashboard.port=8085
jobs.dashboard.enabled=true

# Management Node
management.node.cache.ttl.seconds=60
management.node.request.timeout=60
management.node.base.url={{ .Values.global.managementNode.baseUrl }}

# Client TLS Configuration
client.mtlsEnabled={{ .Values.federatorClient.config.mtlsEnabled | default true }}
client.tlsEnabled={{ .Values.federatorClient.config.tlsEnabled | default true }}
client.p12FilePath=/secrets/federation-client-p12/{{ .Values.secrets.certificates.external.clientP12Filename }}
client.p12Password={{ .Values.secrets.certificates.external.clientP12Password }}
client.truststoreFilePath=/secrets/federation-cert/keycloak.truststore.jks
client.truststorePassword={{ .Values.secrets.certificates.external.truststorePassword }}
client.keystorePassword={{ .Values.secrets.certificates.external.clientKeystorePassword }}

# Connection Configuration
connections.configuration=/client-connections/connection-configuration.json

# File Storage Configuration
client.files.storage.provider={{ .Values.federatorClient.config.storage.provider | upper }}
{{- if eq (.Values.federatorClient.config.storage.provider | upper) "S3" }}
files.s3.bucket={{ .Values.federatorClient.config.storage.s3.bucket }}
aws.s3.region={{ .Values.federatorClient.config.storage.s3.region }}
{{- else if eq (.Values.federatorClient.config.storage.provider | upper) "AZURE" }}
azure.storage.connection.string={{ .Values.federatorClient.config.storage.azure.connectionString }}
azure.storage.account.name={{ .Values.federatorClient.config.storage.azure.accountName }}
azure.storage.endpoint={{ .Values.federatorClient.config.storage.azure.endpoint }}
files.azure.container={{ .Values.federatorClient.config.storage.azure.container }}
{{- else if eq (.Values.federatorClient.config.storage.provider | upper) "LOCAL" }}
client.files.temp.dir={{ .Values.federatorClient.config.storage.local.tempDir | default "" }}
{{- end }}
{{- end }}

{{/*
Server properties file content
*/}}
{{- define "federator-suite.serverProperties" -}}
# Kafka Configuration (Consumer)
kafka.defaultKeyDeserializerClass=org.apache.kafka.common.serialization.StringDeserializer
kafka.defaultValueDeserializerClass=uk.gov.dbt.ndtp.federator.access.AccessMessageDeserializer
kafka.consumerGroup=server.consumer
kafka.pollDuration=PT10S
kafka.pollRecords=100

# Shared Headers
shared.headers=Security-Label^Content-Type
filter.shareAll=false

# Client Name
client.name={{ .Values.federatorServer.config.clientName | default (printf "ndtp.dbt.gov.uk.%s" (.Values.global.orgName | lower)) }}

# Server Configuration
server.port={{ .Values.federatorServer.config.serverPort }}
server.keepAliveTime={{ .Values.federatorServer.config.keepAliveTime | default 10 }}

# Kafka Bootstrap Servers
kafka.bootstrapServers={{ include "federator-suite.kafka.bootstrapServers" . }}
{{- if or .Values.kafka.external (and (not .Values.kafka.external) .Values.kafka.sasl) }}
kafka.additional.security.protocol={{ include "federator-suite.kafka.securityProtocol" . }}
kafka.additional.sasl.mechanism={{ include "federator-suite.kafka.saslMechanism" . }}
kafka.additional.sasl.jaas.config={{ .Values.secrets.kafkaAuth.jaasConfig }}
{{- end }}

# Server mTLS Configuration
server.mtlsEnabled={{ .Values.federatorServer.config.mtlsEnabled | default true }}
server.truststoreFilePath=/secrets/federation-cert/keycloak.truststore.jks
server.truststorePassword={{ .Values.secrets.certificates.external.truststorePassword }}
server.p12FilePath=/secrets/federation-server-p12/{{ .Values.secrets.certificates.external.serverP12Filename }}
server.p12Password={{ .Values.secrets.certificates.external.serverP12Password }}
server.keystorePassword={{ .Values.secrets.certificates.external.serverKeystorePassword }}

# Common Configuration
common.configuration=/common-configuration/common-configuration.properties

# JobRunr Configuration
org.jobrunr.jobs.default-allow-concurrent-execution=false
jobs.dashboard.port=8085
jobs.dashboard.enabled=true

# Management Node
management.node.cache.ttl.seconds=60
management.node.request.timeout=60
management.node.base.url={{ .Values.global.managementNode.baseUrl }}

# Redis/Valkey Configuration
{{- $password := include "federator-suite.valkey.password" . -}}
{{- $redisTlsEnabled := false -}}
{{- if .Values.valkey.external }}
{{- if kindIs "bool" .Values.valkey.external }}
{{- $redisTlsEnabled = true }}
{{- else if .Values.valkey.external.enabled }}
{{- $redisTlsEnabled = true }}
{{- end }}
{{- else if and .Values.valkey.enabled .Values.valkey.valkey.master.tls }}
{{- $redisTlsEnabled = .Values.valkey.valkey.master.tls.enabled }}
{{- end }}
redis.host={{ include "federator-suite.valkey.host" . }}
redis.port={{ include "federator-suite.valkey.port" . }}
redis.tls.enabled={{ ternary "true" "false" $redisTlsEnabled }}
redis.prefix={{ .Values.federatorServer.config.redisPrefix | default (printf "federator-server-%s" (.Values.global.orgName | lower)) }}

# File Storage Configuration
file.stream.chunk.size=1000
{{- if eq (.Values.federatorServer.config.storage.provider | upper) "S3" }}
files.s3.bucket={{ .Values.federatorServer.config.storage.s3.bucket }}
aws.s3.region={{ .Values.federatorServer.config.storage.s3.region }}
{{- else if eq (.Values.federatorServer.config.storage.provider | upper) "AZURE" }}
azure.storage.connection.string={{ .Values.federatorServer.config.storage.azure.connectionString }}
client.files.storage.provider=AZURE
{{- end }}
{{- end }}
