#!/bin/bash

set -u

echo "=== Federator Suite Prerequisites Check ==="
echo ""

MISSING_REQUIRED=0

check_required_cmd() {
	local cmd="$1"
	local label="$2"
	local version_cmd="$3"

	echo -n "${label}: "
	if command -v "$cmd" >/dev/null 2>&1; then
		eval "$version_cmd" 2>/dev/null | head -1
		echo "  ✅"
	else
		echo "❌ MISSING"
		MISSING_REQUIRED=1
	fi
}

check_optional_cmd() {
	local cmd="$1"
	local label="$2"
	local version_cmd="$3"

	echo -n "${label}: "
	if command -v "$cmd" >/dev/null 2>&1; then
		eval "$version_cmd" 2>/dev/null | head -1
		echo "  ✅"
	else
		echo "⚠️  Optional (not installed)"
	fi
}

# Required tools
check_required_cmd docker "Docker" "docker --version"
check_required_cmd kubectl "kubectl" "kubectl version --client"
check_required_cmd helm "Helm" "helm version --short"
check_required_cmd kind "Kind" "kind version"
check_required_cmd openssl "OpenSSL" "openssl version"
check_required_cmd java "Java" "java -version"
check_required_cmd keytool "keytool" "keytool -help"
check_required_cmd make "Make" "make --version"
check_required_cmd yq "yq" "yq --version"

# Optional helpers
check_optional_cmd jq "jq" "jq --version"
check_optional_cmd aws "AWS CLI" "aws --version"
check_optional_cmd az "Azure CLI" "az version"
check_optional_cmd gcloud "GCloud CLI" "gcloud version"

echo ""
echo "Helm repositories:"
if helm repo list 2>/dev/null | grep -q "bitnami"; then
	echo "✅ Bitnami repo is configured"
else
	echo "⚠️  Bitnami repo not found"
	echo "   Note: deploy commands auto-configure this repo when needed"
fi

echo ""
echo "Federator local Docker images (recommended for KIND):"
if docker images 2>/dev/null | grep -q "federator-server.*local"; then
	echo "✅ federator-server:local found"
else
	echo "⚠️  federator-server:local not found"
fi

if docker images 2>/dev/null | grep -q "federator-client.*local"; then
	echo "✅ federator-client:local found"
else
	echo "⚠️  federator-client:local not found"
fi

echo ""
echo "=== Result ==="
if [ "$MISSING_REQUIRED" -eq 0 ]; then
	echo "✅ All required prerequisites are available"
	exit 0
else
	echo "❌ Missing required prerequisites. Fix the items above and rerun."
	exit 1
fi