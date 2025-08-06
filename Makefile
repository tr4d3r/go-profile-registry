# go-profile-registry Makefile

# Build settings
REGISTRY_BUILDER=scripts/registry-builder/registry-builder
MODULES_DIR=./modules
REGISTRY_DIR=./registry

# Default target
.PHONY: all
all: build-registry

# Build registry from modules
.PHONY: build-registry
build-registry:
	@echo "🔨 Building registry from modules..."
	./scripts/build-registry.sh

# Build the registry builder binary
.PHONY: build-builder
build-builder:
	@echo "🔧 Building registry builder..."
	cd scripts/registry-builder && go build -o registry-builder main.go

# Validate all modules
.PHONY: validate
validate: validate-env-vars validate-operational-tiers
	@echo "🔍 Validating modules..."
	@for json_file in $$(find $(MODULES_DIR) -name "*.json"); do \
		echo "Validating $$json_file"; \
		if ! jq empty "$$json_file" 2>/dev/null; then \
			echo "❌ Invalid JSON in: $$json_file"; \
			exit 1; \
		fi; \
	done
	@echo "✅ All modules are valid JSON"

# Validate environment variables in modules
.PHONY: validate-env-vars
validate-env-vars:
	@echo "🔍 Validating environment variables..."
	./scripts/validate-env-vars.sh

# Validate operational tiers in modules
.PHONY: validate-operational-tiers
validate-operational-tiers:
	@echo "🔍 Validating operational tiers..."
	./scripts/validate-operational-tiers.sh

# Validate registry files
.PHONY: validate-registry
validate-registry:
	@echo "🔍 Validating registry files..."
	@for json_file in $$(find $(REGISTRY_DIR) -name "*.json"); do \
		echo "Validating $$json_file"; \
		if ! jq empty "$$json_file" 2>/dev/null; then \
			echo "❌ Invalid JSON in: $$json_file"; \
			exit 1; \
		fi; \
	done
	@echo "✅ All registry files are valid JSON"

# Clean generated files
.PHONY: clean
clean:
	@echo "🧹 Cleaning generated files..."
	@rm -rf $(REGISTRY_DIR)
	@rm -f $(REGISTRY_BUILDER)
	@echo "✅ Cleanup complete"

# Test the registry generation
.PHONY: test
test: validate build-registry validate-registry
	@echo "✅ All tests passed!"

# Show registry statistics
.PHONY: stats
stats: build-registry
	@echo "📊 Registry Statistics:"
	@echo "Modules: $$(find $(MODULES_DIR) -name '*.json' | wc -l)"
	@echo "Categories: $$(jq -r '.categories | length' $(REGISTRY_DIR)/categories.json)"
	@echo "Total size: $$(du -sh $(REGISTRY_DIR) | cut -f1)"

# Create a new module from template
.PHONY: new-module
new-module:
	@./scripts/new-module.sh

# Format Go code
.PHONY: fmt
fmt:
	@echo "🎨 Formatting Go code..."
	@cd scripts/registry-builder && go fmt ./...

# Lint Go code
.PHONY: lint
lint:
	@echo "🔍 Linting Go code..."
	@cd scripts/registry-builder && go vet ./...

# Help
.PHONY: help
help:
	@echo "Available targets:"
	@echo "  build-registry   - Build registry from modules"
	@echo "  build-builder    - Build the registry builder binary"
	@echo "  validate         - Validate all module JSON files"
	@echo "  validate-registry- Validate all registry JSON files"
	@echo "  clean           - Clean generated files"
	@echo "  test            - Run validation and build tests"
	@echo "  stats           - Show registry statistics"
	@echo "  new-module       - Create a new module from template"
	@echo "  fmt             - Format Go code"
	@echo "  lint            - Lint Go code"
	@echo "  help            - Show this help message"
