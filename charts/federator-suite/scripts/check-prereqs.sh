#!/bin/bash
echo "=== Local Development Environment Check ==="
echo ""

# Docker
echo -n "Docker: "
docker --version && echo "✅" || echo "❌ MISSING"

# kubectl
echo -n "kubectl: "
kubectl version --client 2>/dev/null && echo "✅" || echo "❌ MISSING"

# Helm
echo -n "Helm: "
helm version --short 2>/dev/null && echo "✅" || echo "❌ MISSING"

# Kind
echo -n "Kind: "
kind version 2>/dev/null && echo "✅" || echo "❌ MISSING"

# OpenSSL
echo -n "OpenSSL: "
openssl version && echo "✅" || echo "❌ MISSING"

# Java/keytool
echo -n "Java: "
java -version 2>&1 | head -1 && echo "✅" || echo "❌ MISSING"
echo -n "keytool: "
which keytool >/dev/null && echo "✅ $(which keytool)" || echo "❌ MISSING"

# jq (optional)
echo -n "jq: "
jq --version 2>/dev/null && echo "✅" || echo "⚠️  Optional"

# Check Helm repos
echo ""
echo "Helm repositories:"
helm repo list 2>/dev/null | grep bitnami && echo "✅ Bitnami repo added" || echo "❌ Run: helm repo add bitnami https://charts.bitnami.com/bitnami"

# Check Docker images
echo ""
echo "Federator Docker images:"
docker images | grep "federator-server.*local" && echo "✅ Server image exists" || echo "⚠️  Need to build: docker build -t federator-server:local ..."
docker images | grep "federator-client.*local" && echo "✅ Client image exists" || echo "⚠️  Need to build: docker build -t federator-client:local ..."

echo ""
echo "=== Setup Status ==="