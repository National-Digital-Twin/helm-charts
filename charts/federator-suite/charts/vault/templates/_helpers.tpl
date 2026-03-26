{{/* Vault subchart helper - placeholder for future customizations */}}
{{- define "vault-subchart.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}
