# Project Setup
PROJECT_NAME := configuration-aws-dynamodb
PROJECT_REPO := github.com/upbound/$(PROJECT_NAME)

# NOTE(hasheddan): the platform is insignificant here as Configuration package
# images are not architecture-specific. We constrain to one platform to avoid
# needlessly pushing a multi-arch image.
PLATFORMS ?= linux_amd64
-include build/makelib/common.mk

# ====================================================================================
# Setup Kubernetes tools

CHAINSAW_VERSION = 0.2.10
KIND_VERSION = v0.24.0
KUBECTL_VERSION = v1.30.2
UP_VERSION = v0.32.0
UP_CHANNEL = stable
UPTEST_VERSION = v1.2.0
-include build/makelib/k8s_tools.mk
# ====================================================================================
# Setup XPKG

# NOTE(jastang): Configurations deployed in Upbound do not currently follow
# certain conventions such as the default examples root or package directory.
XPKG_DIR = $(shell pwd)
XPKG_EXAMPLES_DIR = examples
XPKG_IGNORE = .github/workflows/ci.yaml,.github/workflows/tag.yml,.github/workflows/e2e.yaml,.github/workflows/yamllint.yaml,init/*.yaml,.work/uptest-datasource.yaml,test/provider/*.yaml,examples/*.yaml,debug/*.yaml,test/*.yaml

XPKG_REG_ORGS ?= xpkg.upbound.io/upbound
# NOTE(hasheddan): skip promoting on xpkg.upbound.io as channel tags are
# inferred.
XPKG_REG_ORGS_NO_PROMOTE ?= xpkg.upbound.io/upbound
XPKGS = $(PROJECT_NAME)
-include build/makelib/xpkg.mk

CROSSPLANE_VERSION = 1.16.0-up.1
CROSSPLANE_CHART_REPO = https://charts.upbound.io/stable
CROSSPLANE_CHART_NAME = universal-crossplane
CROSSPLANE_NAMESPACE = upbound-system
CROSSPLANE_ARGS = "--enable-usages"
KIND_CLUSTER_NAME = uptest-$(PROJECT_NAME)
-include build/makelib/local.xpkg.mk
-include build/makelib/controlplane.mk

# ====================================================================================
# Targets

# run `make help` to see the targets and options

# We want submodules to be set up the first time `make` is run.
# We manage the build/ folder and its Makefiles as a submodule.
# The first time `make` is run, the includes of build/*.mk files will
# all fail, and this target will be run. The next time, the default as defined
# by the includes will be run instead.
fallthrough: submodules
	@echo Initial setup complete. Running make again . . .
	@make

# Update the submodules, such as the common build scripts.
submodules:
	@git submodule sync
	@git submodule update --init --recursive

# We must ensure up is installed in tool cache prior to build as including the k8s_tools machinery prior to the xpkg
# machinery sets UP to point to tool cache.
build.init: $(UP)

# ====================================================================================
# End to End Testing

check:
ifndef UPTEST_CLOUD_CREDENTIALS
	@$(INFO) Please export UPTEST_CLOUD_CREDENTIALS, e.g. \`export UPTEST_CLOUD_CREDENTIALS=\$\(cat \~/.aws/credentials\)\`
	@$(FAIL)
endif

# This target requires the following environment variables to be set:
# - UPTEST_CLOUD_CREDENTIALS, cloud credentials for the provider being tested, e.g. export UPTEST_CLOUD_CREDENTIALS=$(cat ~/.aws/credentials)
# - To ensure the proper functioning of the end-to-end test resource pre-deletion hook, it is crucial to arrange your resources appropriately. 
#   You can check the basic implementation here: https://github.com/upbound/uptest/blob/main/internal/templates/01-delete.yaml.tmpl.
SKIP_DELETE ?=
uptest: $(UPTEST) $(KUBECTL) $(CHAINSAW)
	@$(INFO) running automated tests
	@KUBECTL=$(KUBECTL) CROSSPLANE_NAMESPACE=$(CROSSPLANE_NAMESPACE) CROSSPLANE_CLI=$(CROSSPLANE_CLI) CHAINSAW=$(CHAINSAW) $(UPTEST) e2e examples/instance-without-replica.yaml --data-source="${UPTEST_DATASOURCE_PATH}" --setup-script=test/setup.sh --default-timeout=3600s $(SKIP_DELETE) || $(FAIL)
	@$(OK) running automated tests

# This target requires the following environment variables to be set:
# - UPTEST_CLOUD_CREDENTIALS, cloud credentials for the provider being tested, e.g. export UPTEST_CLOUD_CREDENTIALS=$(cat ~/.aws/credentials)
# Use `make e2e SKIP_DELETE=--skip-delete` to skip deletion of resources created during the test.

# e2e: build controlplane.up local.xpkg.deploy.configuration.$(PROJECT_NAME) uptest

e2e: check build controlplane.down controlplane.up local.xpkg.deploy.configuration.$(PROJECT_NAME) uptest ## Run uptest together with all dependencies. Use `make e2e SKIP_DELETE=--skip-delete` to skip deletion of resources.

render: $(CROSSPLANE_CLI) ${YQ}
	@indir="./examples"; \
	for file in $$(find $$indir -type f -name '*.yaml' ); do \
	    doc_count=$$(grep -c '^---' "$$file"); \
	    if [[ $$doc_count -gt 0 ]]; then \
	        continue; \
	    fi; \
	    COMPOSITION=$$(${YQ} eval '.metadata.annotations."render.crossplane.io/composition-path"' $$file); \
	    FUNCTION=$$(${YQ} eval '.metadata.annotations."render.crossplane.io/function-path"' $$file); \
	    ENVIRONMENT=$$(${YQ} eval '.metadata.annotations."render.crossplane.io/environment-path"' $$file); \
	    OBSERVE=$$(${YQ} eval '.metadata.annotations."render.crossplane.io/observe-path"' $$file); \
	    if [[ "$$ENVIRONMENT" == "null" ]]; then \
	        ENVIRONMENT=""; \
	    fi; \
	    if [[ "$$OBSERVE" == "null" ]]; then \
	        OBSERVE=""; \
	    fi; \
	    if [[ "$$COMPOSITION" == "null" || "$$FUNCTION" == "null" ]]; then \
	        continue; \
	    fi; \
	    ENVIRONMENT=$${ENVIRONMENT=="null" ? "" : $$ENVIRONMENT}; \
	    OBSERVE=$${OBSERVE=="null" ? "" : $$OBSERVE}; \
	    $(CROSSPLANE_CLI) beta render $$file $$COMPOSITION $$FUNCTION $${ENVIRONMENT:+-e $$ENVIRONMENT} $${OBSERVE:+-o $$OBSERVE} -x; \
	done

yamllint:
	@$(INFO) running yamllint
	@yamllint ./apis || $(FAIL)
	@$(OK) running yamllint

help.local:
	@grep -E '^[a-zA-Z_-]+.*:.*?## .*$$' Makefile | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: uptest e2e render yamllint help.local
# .PHONY: uptest e2e render chainsaw chainsaw-test.yaml e2e bootstrap
