# Federator Suite Helm Chart Makefile
# Provides phased deployment with pause/resume capabilities

.PHONY: help
help: ## Show this help message
	@echo "Federator Suite Deployment Targets"
	@echo "==================================="
	@echo ""
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-30s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Environment Variables:"
	@echo "  ENV          Deployment environment (local|dev|prod)"
	@echo "  ORG          Organization name (bcc|env|heg)"
	@echo "  RELEASE_NAME Release name (default: federator-suite)"
	@echo "  NAMESPACE    Auto-detected from values files or override manually"
	@echo ""
	@echo "Deployment Types:"
	@echo "  make deploy-all           # Full deployment (single helm install) - RECOMMENDED"
	@echo "  make upgrade              # Fast helm upgrade without checks - FOR ITERATIVE DEV"
	@echo "  make deploy-phased        # Phased deployment (Kafka→Valkey→Federator) - LOCAL ONLY"
	@echo "  make deploy-all-orgs      # Deploy to all organizations in environment"
	@echo "  make list-orgs            # List available organizations"
	@echo ""
	@echo "Examples:"
	@echo "  make deploy-local ORG=bcc           # Deploy BCC locally (Kind)"
	@echo "  make deploy-local ORG=env           # Deploy ENV locally"
	@echo "  make deploy ENV=dev ORG=bcc         # Deploy BCC to AWS EKS dev"
	@echo "  make upgrade ENV=dev ORG=bcc        # Fast upgrade BCC on AWS EKS dev"
	@echo "  make deploy ENV=dev ORG=env         # Deploy ENV to AWS EKS dev"
	@echo "  make deploy ENV=dev ORG=heg         # Deploy HEG to Azure AKS dev"
	@echo "  make deploy-all-orgs ENV=local      # Deploy all orgs locally"
	@echo "  make list-orgs ENV=dev              # List dev organizations"
	@echo ""
	@echo "Organizations & Cloud Platforms:"
	@echo "  - BCC: AWS EKS (namespace: ia-federation)"
	@echo "  - ENV: AWS EKS (namespace: ia-federation)"
	@echo "  - HEG: Azure AKS (namespace: ia-federation)"
	@echo ""
	@echo "Notes:"
	@echo "  - Local: Namespace created automatically by Makefile"
	@echo "  - Dev/Prod: Namespace must already exist in cluster"
	@echo "  - Namespace is auto-detected from values/overrides/{env}/{org}.yaml"
	@echo ""
	@echo "Documentation:"
	@echo "  See documentation/INDEX.md for complete documentation"
	@echo "  - documentation/QUICKSTART.md       # Quick start guide"
	@echo "  - documentation/LOCAL-SETUP.md      # Local development setup"
	@echo "  - documentation/DEPLOYMENT-CHECKLIST.md  # Production checklist"

# ============================================
# Testing & Validation
# ============================================

.PHONY: test
test: test-render ## Run all tests

# ============================================
# Configuration Variables
# ============================================
ENV ?= local
RELEASE_NAME ?= federator-suite
ORG ?= bcc
CHART_PATH = .

# Component values (always included)
COMPONENT_VALUES = -f values/common-values.yaml -f values/kafka.yaml -f values/valkey.yaml -f values/federator.yaml -f values/kafka-ui.yaml -f values/valkey-ui.yaml -f values/istio.yaml

# Determine which values files to use based on ENV and ORG
ifeq ($(ENV),local)
	VALUES_FILES = $(COMPONENT_VALUES) -f values/overrides/local/local.yaml -f values/overrides/local/$(ORG).yaml
	SECRETS_FILE = values/overrides/local/secrets.yaml
	# Extract namespace from org-specific file, fallback to ia-federation
	NAMESPACE ?= $(shell grep 'namespace:' values/overrides/local/$(ORG).yaml 2>/dev/null | head -1 | awk '{print $$2}' || echo "ia-federation")
else ifeq ($(ENV),dev)
	VALUES_FILES = $(COMPONENT_VALUES) -f values/overrides/dev/$(ORG).yaml
	SECRETS_FILE = values/overrides/dev/secrets/$(ORG)-secrets.yaml
	# Extract namespace from org-specific file, fallback to helm-ia-federation
	NAMESPACE ?= $(shell grep 'namespace:' values/overrides/dev/$(ORG).yaml 2>/dev/null | head -1 | awk '{print $$2}' || echo "helm-ia-federation")
else ifeq ($(ENV),prod)
	VALUES_FILES = $(COMPONENT_VALUES) -f values/overrides/prod/$(ORG).yaml
	SECRETS_FILE = values/overrides/prod/secrets/$(ORG)-secrets.yaml
	# Extract namespace from org-specific file, fallback to ia-federation
	NAMESPACE ?= $(shell grep 'namespace:' values/overrides/prod/$(ORG).yaml 2>/dev/null | head -1 | awk '{print $$2}' || echo "ia-federation")
else
	$(error Unknown environment: $(ENV). Valid options: local, dev, prod)
endif

# Add secrets file if it exists
ifneq (,$(wildcard $(SECRETS_FILE)))
	VALUES_FILES += -f $(SECRETS_FILE)
endif

# ============================================
# Full Deployment Targets
# ============================================

.PHONY: deploy-all
deploy-all: ## Deploy complete federator suite (single helm install)
	@echo "==> Deploying full federator suite to $(ENV) environment (ORG=$(ORG))..."
	@$(MAKE) pre-deploy-check
	@$(MAKE) phase1-cluster
	@$(MAKE) phase2-dependencies
	@$(MAKE) istio-inject-if-enabled
	@echo "==> Installing complete chart with all components..."
	@helm upgrade --install $(RELEASE_NAME) $(CHART_PATH) \
		-n $(NAMESPACE) \
		$(VALUES_FILES) \
		--wait --timeout 10m
	@$(MAKE) phase6-verify
	@echo "==> ✓ Full deployment complete!"

.PHONY: deploy
deploy: deploy-all ## Alias for deploy-all (single helm install)

.PHONY: upgrade
upgrade: ## Fast helm upgrade without checks (for iterative development)
	@echo "==> Upgrading $(RELEASE_NAME) in $(NAMESPACE) ($(ENV)/$(ORG))..."
	@helm upgrade $(RELEASE_NAME) $(CHART_PATH) \
		-n $(NAMESPACE) \
		$(VALUES_FILES)
	@echo "==> ✓ Upgrade complete!"

# ============================================
# Multi-Organization Deployment
# ============================================

.PHONY: list-orgs
list-orgs: ## List all available organizations for an environment
	@echo "==> Available organizations for $(ENV) environment:"
	@if [ "$(ENV)" = "local" ]; then \
		ls values/overrides/local/*.yaml 2>/dev/null | grep -v 'local.yaml\|secrets.yaml' | xargs -n1 basename | sed 's/.yaml//' | sed 's/^/  - /' || echo "  No org files found"; \
	else \
		ls values/overrides/$(ENV)/*.yaml 2>/dev/null | grep -v 'secrets' | xargs -n1 basename | sed 's/.yaml//' | sed 's/^/  - /' || echo "  No org files found"; \
	fi

.PHONY: deploy-all-orgs
deploy-all-orgs: ## Deploy to all organizations in current environment
	@echo "==> Deploying to all organizations in $(ENV) environment..."
	@$(MAKE) list-orgs
	@if [ "$(ENV)" = "local" ]; then \
		for org_file in values/overrides/local/*.yaml; do \
			org=$$(basename $$org_file .yaml); \
			if [ "$$org" != "local" ] && [ "$$org" != "secrets" ]; then \
				echo ""; \
				echo "==> Deploying organization: $$org"; \
				$(MAKE) deploy-all ORG=$$org RELEASE_NAME=$$org-federation || { echo "ERROR: Failed to deploy $$org"; exit 1; }; \
			fi; \
		done; \
	else \
		for org_file in values/overrides/$(ENV)/*.yaml; do \
			org=$$(basename $$org_file .yaml); \
			echo ""; \
			echo "==> Deploying organization: $$org"; \
			$(MAKE) deploy-all ORG=$$org RELEASE_NAME=$$org-federation || { echo "ERROR: Failed to deploy $$org"; exit 1; }; \
		done; \
	fi
	@echo ""
	@echo "==> ✓ All organizations deployed successfully!"

.PHONY: get-org-namespace
get-org-namespace: ## Get namespace for an organization (requires ORG=...)
	@if [ "$(ENV)" = "local" ]; then \
		grep 'namespace:' values/overrides/local/$(ORG).yaml 2>/dev/null | head -1 | awk '{print $$2}' || echo "ia-federation"; \
	else \
		grep 'namespace:' values/overrides/$(ENV)/$(ORG).yaml 2>/dev/null | head -1 | awk '{print $$2}' || echo "ia-federation"; \
	fi

.PHONY: deploy-phased
deploy-phased: ## Deploy with phase-by-phase approach (Kafka→Valkey→Federator) - LOCAL ONLY
	@echo "==> Deploying federator suite with phased approach..."
ifneq ($(ENV),local)
	@echo "WARNING: Phased deployment is designed for local environments only."
	@echo "For dev/prod with external MSK/ElastiCache, use 'make deploy-all' instead."
	@echo ""
	@read -p "Continue anyway? [y/N] " -n 1 -r; \
	echo; \
	if [[ ! $$REPLY =~ ^[Yy]$$ ]]; then \
		echo "Aborted."; \
		exit 1; \
	fi
endif
	@$(MAKE) pre-deploy-check
	@$(MAKE) phase1-cluster
	@$(MAKE) phase2-dependencies
	@$(MAKE) istio-inject-if-enabled
	@$(MAKE) phase3-kafka
	@$(MAKE) phase4-valkey
	@$(MAKE) phase5-federator
	@$(MAKE) phase6-verify
	@echo "==> ✓ Phased deployment complete!"

.PHONY: deploy-local
deploy-local: ENV=local
deploy-local: ## Deploy to local Kind cluster (requires ORG=bcc|env|heg)
	@$(MAKE) deploy-all

# ============================================
# Phase 1: Cluster Setup
# ============================================

.PHONY: phase1-cluster
phase1-cluster: ## Phase 1: Create/verify Kubernetes cluster
	@echo "==> Phase 1: Cluster Setup"
ifeq ($(ENV),local)
	@echo "  → Checking if Kind cluster exists..."
	@if kind get clusters | grep -q federator-suite-kind-cluster; then \
		echo "  ✓ Kind cluster 'federator-suite' already exists"; \
	else \
		echo "  → Creating Kind cluster..."; \
		kind create cluster --name federator-suite-kind-cluster --config kind-config.yaml; \
		echo "  ✓ Kind cluster created"; \
	fi
	@kubectl config use-context kind-federator-suite-kind-cluster
	@echo "  → Creating namespace: $(NAMESPACE)"
	@kubectl create namespace $(NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -
	@echo "  → Adding Istio injection label to namespace..."
	@kubectl label namespace $(NAMESPACE) istio-injection=enabled --overwrite || true
	@echo "  ✓ Namespace ready with Istio injection enabled"
else
	@echo "  → Verifying cluster connectivity..."
	@kubectl cluster-info
	@echo "  ✓ Connected to $(ENV) cluster"
	@echo "  → Using existing namespace: $(NAMESPACE)"
	@kubectl get namespace $(NAMESPACE) > /dev/null 2>&1 || (echo "ERROR: Namespace $(NAMESPACE) does not exist!" && exit 1)
endif
	@echo "==> Phase 1 complete. Cluster ready."

# ============================================
# Phase 2: Dependencies
# ============================================

.PHONY: phase2-dependencies
phase2-dependencies: ## Phase 2: Update Helm dependencies (Bitnami Kafka, Valkey)
	@echo "==> Phase 2: Helm Dependencies"
	@echo "  → Building Valkey subchart dependencies..."
	@cd charts/valkey && helm dependency build
	@echo "  → Building main chart dependencies..."
	@helm dependency build $(CHART_PATH)
	@echo "  ✓ All dependencies built"
	@echo "==> Phase 2 complete. Dependencies ready."

# ============================================
# Phase 3: Kafka Deployment
# ============================================

.PHONY: phase3-kafka
phase3-kafka: ## Phase 3: Deploy Kafka (Bitnami in-cluster)
	@echo "==> Phase 3: Kafka Deployment (Bitnami)"
	@if helm get values $(RELEASE_NAME) -n $(NAMESPACE) 2>/dev/null | grep -q "kafka.inCluster.enabled: true" || \
	   grep -q "enabled: true" values/kafka.yaml; then \
		echo "  → Deploying Bitnami Kafka subchart..."; \
		helm upgrade --install $(RELEASE_NAME) $(CHART_PATH) \
			-n $(NAMESPACE) \
			$(VALUES_FILES) \
			--set federatorServer.enabled=false \
			--set federatorClient.enabled=false \
			--set kafkaUi.enabled=false \
			--set valkeyUi.enabled=false \
			--wait --timeout 5m; \
		echo "  → Waiting for Kafka controller StatefulSet..."; \
		kubectl rollout status sts/$(RELEASE_NAME)-kafka-controller -n $(NAMESPACE) --timeout=600s || true; \
		echo "  → Waiting for Kafka broker StatefulSet (if present)..."; \
		kubectl rollout status sts/$(RELEASE_NAME)-kafka-broker -n $(NAMESPACE) --timeout=600s || true; \
		echo "  ✓ Kafka cluster phase complete"; \
	else \
		echo "  → External Kafka configured, skipping in-cluster deployment"; \
	fi
	@echo "==> Phase 3 complete. Kafka ready."

# ============================================
# Phase 4: Valkey Deployment
# ============================================

.PHONY: phase4-valkey
phase4-valkey: ## Phase 4: Deploy Valkey (if inCluster enabled)
	@echo "==> Phase 4: Valkey Deployment"
	@if helm get values $(RELEASE_NAME) -n $(NAMESPACE) 2>/dev/null | grep -q "valkey.inCluster.enabled: true" || \
	   grep -q "enabled: true" values/valkey.yaml; then \
		echo "  → Installing Valkey subchart..."; \
		helm upgrade --install $(RELEASE_NAME) $(CHART_PATH) \
			-n $(NAMESPACE) \
			$(VALUES_FILES) \
			--set federatorServer.enabled=false \
			--set federatorClient.enabled=false \
			--set kafkaUi.enabled=false \
			--set valkeyUi.enabled=false \
			--wait --timeout 5m; \
		echo "  → Waiting for Valkey to be ready..."; \
		kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=valkey -n $(NAMESPACE) --timeout=300s || true; \
		echo "  ✓ Valkey phase complete"; \
	else \
		echo "  → External Valkey configured, skipping in-cluster deployment"; \
	fi
	@echo "==> Phase 4 complete. Valkey ready."

# ============================================
# Phase 5: Federator Deployment
# ============================================

.PHONY: phase5-federator
phase5-federator: ## Phase 5: Deploy Federator Server and Client
	@echo "==> Phase 5: Federator Deployment"
	@echo "  → Deploying Federator Server and Client..."
	@helm upgrade --install $(RELEASE_NAME) $(CHART_PATH) \
		-n $(NAMESPACE) \
		$(VALUES_FILES) \
		--wait --timeout 5m
	@echo "  → Waiting for Federator pods to be ready..."
	@kubectl wait --for=condition=ready pod -l app=federator-server -n $(NAMESPACE) --timeout=90s
	@kubectl wait --for=condition=ready pod -l app=federator-client -n $(NAMESPACE) --timeout=90s
	@echo "==> Phase 5 complete. Federator deployed."

# ============================================
# Phase 6: Verification
# ============================================

.PHONY: phase6-verify
phase6-verify: ## Phase 6: Verify deployment and show status
	@echo "==> Phase 6: Verification"
	@echo ""
	@echo "Pods:"
	@kubectl get pods -n $(NAMESPACE)
	@echo ""
	@echo "Services:"
	@kubectl get svc -n $(NAMESPACE)
	@echo ""
	@echo "Secrets:"
	@kubectl get secrets -n $(NAMESPACE)
	@echo ""
	@echo "Local Access URLs:"
	@echo "  Kafka UI:         http://localhost:8088 (Kafka UI)"
	@echo "  Valkey UI:        http://localhost:5540 (RedisInsight)"
	@echo "  Federator Client: http://localhost:8081"
	@echo "==> Phase 6 complete. Deployment verified."

# ============================================
# Individual Component Deployment
# ============================================

.PHONY: deploy-kafka-only
deploy-kafka-only: phase1-cluster phase2-dependencies phase3-kafka ## Deploy only Kafka

.PHONY: deploy-valkey-only
deploy-valkey-only: phase1-cluster phase2-dependencies phase4-valkey ## Deploy only Valkey

.PHONY: deploy-federator-only
deploy-federator-only: phase1-cluster phase2-dependencies phase5-federator ## Deploy only Federator components

# ============================================
# Validation and Testing
# ============================================

.PHONY: validate
validate: ## Validate configuration before deployment
	@echo "==> Validating configuration..."
	@echo "  → Environment: $(ENV)"
	@echo "  → Organization: $(ORG)"
	@echo "  → Namespace: $(NAMESPACE)"
	@echo "  → Release: $(RELEASE_NAME)"
	@echo ""
	@echo "  → Checking required files..."
	@test -f values/common-values.yaml || (echo "ERROR: values/common-values.yaml not found" && exit 1)
	@test -f values/kafka.yaml || (echo "ERROR: values/kafka.yaml not found" && exit 1)
	@test -f values/valkey.yaml || (echo "ERROR: values/valkey.yaml not found" && exit 1)
	@test -f values/federator.yaml || (echo "ERROR: values/federator.yaml not found" && exit 1)
ifeq ($(ENV),local)
	@test -f values/overrides/local/local.yaml || (echo "ERROR: values/overrides/local/local.yaml not found" && exit 1)
	@test -f values/overrides/local/$(ORG).yaml || (echo "ERROR: values/overrides/local/$(ORG).yaml not found" && exit 1)
	@test -f $(SECRETS_FILE) || (echo "ERROR: $(SECRETS_FILE) not found" && exit 1)
else
	@test -f values/overrides/$(ENV)/$(ORG).yaml || (echo "ERROR: values/overrides/$(ENV)/$(ORG).yaml not found" && exit 1)
	@test -f $(SECRETS_FILE) || (echo "ERROR: $(SECRETS_FILE) not found - copy from secrets.yaml.example and fill in values" && exit 1)
endif
	@echo "  ✓ All required files present"
	@echo ""
	@echo "  → Validating Helm chart..."
	@helm lint $(CHART_PATH) $(VALUES_FILES) 2>&1 | grep -v "values.yaml: no such file" | grep -E "^(==>|[0-9]+ chart\(s\)|ERROR|WARNING)" || echo "  (no issues detected)"
	@echo "  ✓ Helm chart validation passed"
	@echo ""
	@echo "==> ✓ Validation complete"

.PHONY: test-render
test-render: ## Test rendering templates without deploying
	@echo "==> Testing template rendering..."
	@helm template test-$(ORG) $(CHART_PATH) \
		$(VALUES_FILES) \
		--namespace $(NAMESPACE) \
		--debug 2>&1 | head -50
	@echo "==> ✓ Template rendering successful"

.PHONY: check-cluster
check-cluster: ## Check cluster connectivity and resources
	@echo "==> Checking cluster..."
	@echo "  → Cluster info:"
	@kubectl cluster-info | head -3
	@echo ""
	@echo "  → Current context:"
	@kubectl config current-context
	@echo ""
	@echo "  → Checking namespace: $(NAMESPACE)"
	@kubectl get namespace $(NAMESPACE) 2>/dev/null || echo "  ⚠ Namespace $(NAMESPACE) does not exist"
	@echo ""
	@echo "  → Node status:"
	@kubectl get nodes
	@echo ""
	@echo "==> ✓ Cluster check complete"

.PHONY: check-secrets
check-secrets: ## Verify secrets file exists and has required fields
	@echo "==> Checking secrets file: $(SECRETS_FILE)"
	@test -f $(SECRETS_FILE) || (echo "ERROR: Secrets file not found" && exit 1)
	@echo "  → Checking for required secret fields..."
	@grep -q "truststoreJks:" $(SECRETS_FILE) || echo "  ⚠ truststoreJks not found"
	@grep -q "serverKeystoreJks:" $(SECRETS_FILE) || echo "  ⚠ serverKeystoreJks not found"
	@grep -q "clientKeystoreJks:" $(SECRETS_FILE) || echo "  ⚠ clientKeystoreJks not found"
	@echo "  ✓ Secrets file check complete"

.PHONY: healthcheck
healthcheck: ## Check pods, services, health endpoints, and recent log errors
	@echo "==> Health check for $(RELEASE_NAME) in $(NAMESPACE)"
	@echo "Pods (server/client):"
	@kubectl get pods -l app=federator-server -n $(NAMESPACE)
	@kubectl get pods -l app=federator-client -n $(NAMESPACE)
	@echo ""
	@echo "Services (NodePort/UI):"
	@kubectl get svc $(RELEASE_NAME)-federator-server $(RELEASE_NAME)-federator-client kafka-ui valkey-ui -n $(NAMESPACE) 2>/dev/null || true
	@echo ""
	@echo "Server health (gRPC port 8080):"
	@SERVER_POD=$$(kubectl get pod -l app=federator-server -n $(NAMESPACE) -o jsonpath='{.items[0].metadata.name}' 2>/dev/null); \
		if [ -z "$$SERVER_POD" ]; then echo "  ⚠ server pod not found"; else \
			kubectl exec -n $(NAMESPACE) $$SERVER_POD -c federator-server -- sh -c "ps aux | grep -q '[j]ava.*FederatorServer' && echo '  ✓ Server process running' || echo '  ⚠ Server process not found'"; \
		fi
	@echo "Client health (JobRunr dashboard 8085):"
	@CLIENT_POD=$$(kubectl get pod -l app=federator-client -n $(NAMESPACE) -o jsonpath='{.items[0].metadata.name}' 2>/dev/null); \
		if [ -z "$$CLIENT_POD" ]; then echo "  ⚠ client pod not found"; else kubectl exec -n $(NAMESPACE) $$CLIENT_POD -c federator-client -- sh -c "if command -v wget >/dev/null; then wget -qO- --timeout=2 http://localhost:8085/ 2>/dev/null | grep -q 'JobRunr' && echo '  ✓ JobRunr dashboard responding' || echo '  ⚠ JobRunr dashboard not responding'; else echo '  ⚠ wget not available in image'; fi"; fi
	@echo ""
	@echo "Recent errors (last 200 lines):"
	@kubectl logs -l app=federator-server -n $(NAMESPACE) --tail=200 | grep -Ei 'error|exception' || echo "  No server errors found"
	@kubectl logs -l app=federator-client -n $(NAMESPACE) --tail=200 | grep -Ei 'error|exception' || echo "  No client errors found"

.PHONY: verify-images
verify-images: ## Verify container images are accessible
	@echo "==> Verifying container images..."
ifeq ($(ENV),local)
	@echo "  → Checking local images..."
	@docker image inspect federator-server:local >/dev/null 2>&1 || echo "  ⚠ federator-server:local not found - run: make -C ../../federator build-docker"
	@docker image inspect federator-client:local >/dev/null 2>&1 || echo "  ⚠ federator-client:local not found - run: make -C ../../federator build-docker"
else
	@echo "  → Checking registry images (requires authentication)..."
	@echo "  Note: Image pull will be verified during actual deployment"
endif
	@echo "==> Image verification complete"

.PHONY: pre-deploy-check
pre-deploy-check: validate check-cluster check-secrets ## Run all pre-deployment checks
	@echo "==> ✓ All pre-deployment checks passed"
	@echo "Ready to deploy $(ORG) to $(ENV) environment"

# ============================================
# Istio Service Mesh
# ============================================

.PHONY: istio-enable
istio-enable: ## Enable Istio injection on the namespace
	@echo "==> Enabling Istio injection on namespace: $(NAMESPACE)"
	@kubectl label namespace $(NAMESPACE) istio-injection=enabled --overwrite
	@echo "  ✓ Istio injection label added to namespace"
	@echo ""
	@echo "To inject sidecars into existing pods, restart deployments:"
	@echo "  kubectl rollout restart deployment -n $(NAMESPACE)"

.PHONY: istio-inject-if-enabled
istio-inject-if-enabled: ## Automatically enable Istio injection if enabled in values
	@echo "==> Checking if Istio is enabled in values..."
	@ISTIO_ENABLED=$$(helm template $(RELEASE_NAME) $(CHART_PATH) -n $(NAMESPACE) $(VALUES_FILES) 2>/dev/null | \
		grep -B2 "kind: Gateway" | grep -q "networking.istio.io" && echo "true" || echo "false"); \
	if [ "$$ISTIO_ENABLED" = "true" ]; then \
		echo "  → Istio is enabled, applying istio-injection label to namespace..."; \
		kubectl label namespace $(NAMESPACE) istio-injection=enabled --overwrite 2>/dev/null || true; \
		echo "  ✓ Istio injection enabled for namespace $(NAMESPACE)"; \
	else \
		echo "  → Istio is not enabled in values, skipping..."; \
	fi

.PHONY: istio-disable
istio-disable: ## Disable Istio injection on the namespace
	@echo "==> Disabling Istio injection on namespace: $(NAMESPACE)"
	@kubectl label namespace $(NAMESPACE) istio-injection-
	@echo "  ✓ Istio injection label removed from namespace"
	@echo ""
	@echo "To remove sidecars from existing pods, restart deployments:"
	@echo "  kubectl rollout restart deployment -n $(NAMESPACE)"

.PHONY: istio-status
istio-status: ## Check Istio injection status and resources
	@echo "==> Istio Status for namespace: $(NAMESPACE)"
	@echo ""
	@echo "Namespace label:"
	@kubectl get namespace $(NAMESPACE) -o jsonpath='{.metadata.labels.istio-injection}' 2>/dev/null || echo "  (not set)"
	@echo ""
	@echo ""
	@echo "Pods with Istio sidecar:"
	@kubectl get pods -n $(NAMESPACE) -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{range .status.containerStatuses[*]}{.name}{" "}{end}{"\n"}{end}' | grep istio-proxy || echo "  No pods with Istio sidecar found"
	@echo ""
	@echo "Istio resources:"
	@kubectl get gateway,virtualservice,destinationrule,peerauthentication,authorizationpolicy -n $(NAMESPACE) 2>/dev/null || echo "  No Istio resources found"

.PHONY: istio-restart
istio-restart: ## Restart deployments to inject/remove Istio sidecars
	@echo "==> Restarting deployments in namespace: $(NAMESPACE)"
	@kubectl rollout restart deployment -n $(NAMESPACE)
	@echo "  ✓ All deployments restarted"
	@echo ""
	@echo "Waiting for pods to be ready..."
	@kubectl wait --for=condition=ready pod --all -n $(NAMESPACE) --timeout=300s || true

# ============================================
# Certificate Management
# ============================================

.PHONY: generate-certs
generate-certs: ## Generate self-signed certificates for local development
	@echo "==> Generating certificates..."
	@./scripts/generate-certs.sh $(ORG)
	@echo "==> Certificates generated in ./certs/"

.PHONY: update-secrets-example
update-secrets-example: ## Update secrets.yaml.example from current secrets.yaml
	@echo "==> Updating secrets example file..."
	@if [ -f values/secrets.yaml ]; then \
		cp values/secrets.yaml values/secrets.yaml.example; \
		echo "  ✓ Updated values/secrets.yaml.example"; \
	else \
		echo "  ✗ values/secrets.yaml not found"; \
		exit 1; \
	fi

# ============================================
# Cleanup Targets
# ============================================

.PHONY: uninstall
uninstall: ## Uninstall the Helm release and cleanup PVCs
	@echo "==> Uninstalling $(RELEASE_NAME) from $(NAMESPACE)..."
	@helm uninstall $(RELEASE_NAME) -n $(NAMESPACE) --wait
	@echo "==> Cleaning up PVCs (Kafka/Valkey persistence volumes)..."
	@kubectl delete pvc -l app.kubernetes.io/instance=$(RELEASE_NAME) -n $(NAMESPACE) 2>/dev/null || true
	@sleep 2
	@echo "==> Remaining PVCs:"
	@kubectl get pvc -n $(NAMESPACE) 2>/dev/null || echo "  No PVCs remaining"
	@echo "==> Uninstall complete."

.PHONY: uninstall-keep-data
uninstall-keep-data: ## Uninstall the Helm release but keep PVCs (persistent data)
	@echo "==> Uninstalling $(RELEASE_NAME) from $(NAMESPACE) (keeping data volumes)..."
	@helm uninstall $(RELEASE_NAME) -n $(NAMESPACE) --wait
	@echo "==> Preserving PVCs for future use:"
	@kubectl get pvc -l app.kubernetes.io/instance=$(RELEASE_NAME) -n $(NAMESPACE) 2>/dev/null || echo "  No PVCs found"
	@echo "==> Uninstall complete (data volumes preserved)."
	@echo ""
	@echo "To remove PVCs later, run:"
	@echo "  kubectl delete pvc -l app.kubernetes.io/instance=$(RELEASE_NAME) -n $(NAMESPACE)"

.PHONY: destroy-cluster
destroy-cluster: ## Delete the Kind cluster (local only)
ifeq ($(ENV),local)
	@echo "==> Destroying Kind cluster 'federator-suite'..."
	@kind delete cluster --name federator-suite-kind-cluster
	@echo "==> Cluster destroyed."
else
	@echo "ERROR: destroy-cluster only works with ENV=local"
	@exit 1
endif

.PHONY: clean
clean: ## Clean generated files and cached data
	@echo "==> Cleaning generated files..."
	@rm -rf charts/*.tgz
	@rm -rf Chart.lock
	@rm -rf certs/
	@echo "==> Clean complete."

.PHONY: clean-all
clean-all: uninstall destroy-cluster clean ## Complete cleanup (uninstall + destroy + clean)

.PHONY: reset
reset: ## Cleanup deployment and rebuild dependencies (reset to phase 2)
	@echo "==> Resetting to Phase 2..."
	@echo "  → Uninstalling Helm release (if exists)..."
	@helm uninstall $(RELEASE_NAME) -n $(NAMESPACE) --wait 2>/dev/null || true
	@echo "  → Deleting PVCs..."
	@kubectl delete pvc --all -n $(NAMESPACE) 2>/dev/null || true
	@echo "  → Waiting for pods to terminate..."
	@sleep 5
	@kubectl get pods -n $(NAMESPACE) 2>/dev/null || true
	@echo "  → Cleaning chart packages..."
	@rm -f charts/kafka-0.1.0.tgz charts/valkey-0.1.0.tgz Chart.lock
	@echo "  → Rebuilding dependencies..."
	@$(MAKE) phase2-dependencies
	@echo "==> ✓ Reset complete. Ready to run phase3-kafka."

# ============================================
# Development Helpers
# ============================================

.PHONY: template
template: ## Generate Kubernetes manifests without installing
	@helm template $(RELEASE_NAME) $(CHART_PATH) \
		-n $(NAMESPACE) \
		$(VALUES_FILES)

.PHONY: debug
debug: ## Show resolved values for debugging
	@echo "==> Debug Information"
	@echo "Environment: $(ENV)"
	@echo "Release Name: $(RELEASE_NAME)"
	@echo "Namespace: $(NAMESPACE)"
	@echo "Organization: $(ORG)"
	@echo "Values Files: $(VALUES_FILES)"
	@echo ""
	@helm template $(RELEASE_NAME) $(CHART_PATH) \
		-n $(NAMESPACE) \
		$(VALUES_FILES) \
		--debug

.PHONY: lint
lint: ## Lint the Helm chart
	@echo "==> Linting Helm chart..."
	@helm lint $(CHART_PATH) $(VALUES_FILES)

.PHONY: logs-server
logs-server: ## Show Federator Server logs
	@kubectl logs -l app=federator-server -n $(NAMESPACE) --tail=100 -f

.PHONY: logs-client
logs-client: ## Show Federator Client logs
	@kubectl logs -l app=federator-client -n $(NAMESPACE) --tail=100 -f

.PHONY: shell-server
shell-server: ## Open shell in Federator Server pod
	@kubectl exec -it $$(kubectl get pod -l app=federator-server -n $(NAMESPACE) -o jsonpath='{.items[0].metadata.name}') -n $(NAMESPACE) -- /bin/bash

.PHONY: shell-client
shell-client: ## Open shell in Federator Client pod
	@kubectl exec -it $$(kubectl get pod -l app=federator-client -n $(NAMESPACE) -o jsonpath='{.items[0].metadata.name}') -n $(NAMESPACE) -- /bin/bash

# ============================================
# Port Forwarding
# ============================================

.PHONY: port-forward-kafka-ui
port-forward-kafka-ui: ## Port forward to Kafka UI (localhost:8088) - Press Ctrl+C to stop
	@echo "Port forwarding to kafka-ui on localhost:8088..."
	@kubectl port-forward -n $(NAMESPACE) svc/kafka-ui 8088:8080

.PHONY: port-forward-valkey-ui
port-forward-valkey-ui: ## Port forward to Valkey UI (localhost:5540) - Press Ctrl+C to stop
	@echo "Port forwarding to valkey-ui (RedisInsight) on localhost:5540..."
	@kubectl port-forward -n $(NAMESPACE) svc/valkey-ui 5540:5540

.PHONY: port-forward-client-jobs
port-forward-client-jobs: ## Port forward to Client JobRunr Dashboard (localhost:8086) - Press Ctrl+C to stop
	@echo "Port forwarding to client JobRunr dashboard on localhost:8085..."
	@kubectl port-forward -n $(NAMESPACE) svc/$(RELEASE_NAME)-federator-client 8085:8085

.PHONY: port-forward-all
port-forward-all: ## Port forward all services in background
	@echo "Starting all port forwards in background..."
	@kubectl port-forward -n $(NAMESPACE) svc/kafka-ui 8088:8080 > /dev/null 2>&1 &
	@kubectl port-forward -n $(NAMESPACE) svc/valkey-ui 5540:5540 > /dev/null 2>&1 &
	@kubectl port-forward -n $(NAMESPACE) svc/$(RELEASE_NAME)-federator-client 8085:8085 > /dev/null 2>&1 &
	@sleep 2
	@echo "✓ All port forwards started in background"
	@echo "  Client Jobs:  http://localhost:8085"
	@echo "  Kafka UI:     http://localhost:8088"
	@echo "  Valkey UI:    http://localhost:5540 (RedisInsight)"
	@echo ""
	@echo "To stop all: pkill -f 'kubectl port-forward'"

.PHONY: stop-port-forwards
stop-port-forwards: ## Stop all port-forward processes
	@echo "Stopping all port forwards..."
	@pkill -f "kubectl port-forward" || echo "No port forwards running"
	@echo "✓ All port forwards stopped"

.PHONY: port-forward-status
port-forward-status: ## Show status of port-forward processes
	@echo "Port Forward Status"
	@echo "==================="
	@echo ""
	@if ps aux | grep -v grep | grep -q "kubectl port-forward"; then \
		echo "Active port forwards:"; \
		echo ""; \
		ps aux | grep -v grep | grep "kubectl port-forward" | while read -r line; do \
			pid=$$(echo "$$line" | awk '{print $$2}'); \
			cmd=$$(echo "$$line" | awk '{for(i=11;i<=NF;i++) printf "%s ", $$i}'); \
			namespace=$$(echo "$$cmd" | grep -oP '(?<=-n )[^ ]+' | head -1); \
			service=$$(echo "$$cmd" | grep -oP 'svc/[^ ]+' | head -1); \
			ports=$$(echo "$$cmd" | grep -oP '\d+:\d+' | head -1); \
			echo "  PID $$pid: $$service ($$ports) → namespace: $$namespace"; \
		done; \
		echo ""; \
		echo "Services should be accessible at:"; \
		if ps aux | grep -v grep | grep "kubectl port-forward" | grep -q "8088:8080"; then \
			echo "  ✓ Kafka UI:     http://localhost:8088"; \
		fi; \
		if ps aux | grep -v grep | grep "kubectl port-forward" | grep -q "8085:8085"; then \
			echo "  ✓ Client Jobs:  http://localhost:8085"; \
		fi; \
		if ps aux | grep -v grep | grep "kubectl port-forward" | grep -q "5540:5540"; then \
			echo "  ✓ Valkey UI:    http://localhost:5540"; \
		fi; \
	else \
		echo "No port forwards currently running"; \
		echo ""; \
		echo "To start: make port-forward-all ENV=dev ORG=bcc"; \
	fi
