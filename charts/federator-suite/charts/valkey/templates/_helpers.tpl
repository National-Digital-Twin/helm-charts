{{/* Valkey subchart helper - placeholder for future customizations */}}
{{- define "valkey.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}
