SHELL := /bin/bash

ENV ?= dev
TF_DIR := terraform/environments/$(ENV)

.PHONY: help lint fmt tf-init tf-plan tf-apply tf-destroy helm-lint helm-template test

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS=":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

lint: ## Lint Bash scripts and Terraform
	shellcheck -x scripts/*.sh scripts/lib/*.sh
	terraform -chdir=$(TF_DIR) fmt -check -recursive ../../

fmt: ## Format Terraform
	terraform -chdir=terraform fmt -recursive

tf-init: ## terraform init for ENV
	terraform -chdir=$(TF_DIR) init

tf-plan: ## terraform plan for ENV
	terraform -chdir=$(TF_DIR) plan -out=tfplan

tf-apply: ## terraform apply for ENV
	terraform -chdir=$(TF_DIR) apply -auto-approve tfplan

tf-destroy: ## terraform destroy for ENV
	terraform -chdir=$(TF_DIR) destroy

helm-lint: ## Lint the app Helm chart
	helm lint kubernetes/helm/app-chart

helm-template: ## Render Helm chart with sample values
	helm template ./kubernetes/helm/app-chart \
		--values examples/sample-app/values.yaml

test: ## Run bats tests for Bash scripts
	bats scripts/tests/
