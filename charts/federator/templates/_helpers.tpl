{{- define "federator.name" -}}
{{- $mode := include "federator.mode" . -}}
{{- $base := default .Chart.Name .Values.nameOverride -}}
{{- $suffix := printf "-%s" $mode -}}
{{- if hasSuffix $suffix $base -}}
{{- $base | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s%s" $base $suffix | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "federator.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $mode := include "federator.mode" . -}}
{{- $base := default .Release.Name .Values.nameOverride -}}
{{- $suffix := printf "-%s" $mode -}}
{{- if hasSuffix $suffix $base -}}
{{- $base | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s%s" $base $suffix | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "federator.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" -}}
{{- end -}}

{{- define "federator.mode" -}}
{{- default "server" .Values.mode | lower -}}
{{- end -}}

{{- define "federator.selectorLabels" -}}
app.kubernetes.io/name: {{ include "federator.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: {{ include "federator.mode" . }}
{{- end -}}

{{- define "federator.labels" -}}
helm.sh/chart: {{ include "federator.chart" . }}
{{ include "federator.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: Helm
{{- end -}}

{{- define "federator.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "federator.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{- define "federator.image" -}}
{{- $mode := include "federator.mode" . -}}
{{- $image := index .Values.images $mode -}}
{{- if not $image -}}
{{- fail (printf "Unsupported mode '%s'. Valid values are 'server' or 'client'." $mode) -}}
{{- end -}}
{{- $repository := default $image.repository .Values.image.repository -}}
{{- if not $repository -}}
{{- fail "Image repository must be provided" -}}
{{- end -}}
{{- $tag := (.Values.image.tag | default $image.tag | default .Chart.AppVersion) -}}
{{- printf "%s:%s" $repository $tag -}}
{{- end -}}

{{- define "federator.configSecretName" -}}
{{- $secret := .Values.secretConfig | default (dict) -}}
{{- if $secret.name -}}
{{- $secret.name -}}
{{- else if $secret.create -}}
{{- include "federator.fullname" . | printf "%s-config" -}}
{{- end -}}
{{- end -}}
