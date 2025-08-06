#!/bin/bash

# Validate operational tiers in modules
# This script checks that all modules have valid operational tier definitions

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
MODULES_DIR="$REPO_ROOT/modules"
SCHEMA_FILE="$REPO_ROOT/schemas/operational-tiers.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
total_modules=0
valid_modules=0
invalid_modules=0
warnings=0

echo "🔍 Validating operational tiers in modules..."
echo

# Check if schema file exists
if [[ ! -f "$SCHEMA_FILE" ]]; then
    echo -e "${RED}❌ Operational tiers schema not found: $SCHEMA_FILE${NC}"
    exit 1
fi

# Valid values for validation
declare -a VALID_DEPLOYMENT=("local" "container" "cloud" "bare-metal" "hybrid")
declare -a VALID_ENVIRONMENTS=("development" "staging" "production")
declare -a VALID_CONSTRAINTS=("network_required" "network_optional" "gpu_required" "gpu_optional" "privileged_access" "security_compliance" "platform_specific" "high_memory" "high_cpu" "persistent_storage")

# Function to check if value is in array
contains_element() {
    local element="$1"
    shift
    local array=("$@")
    for item in "${array[@]}"; do
        if [[ "$item" == "$element" ]]; then
            return 0
        fi
    done
    return 1
}

# Function to validate operational tiers in a module
validate_module_tiers() {
    local module_file="$1"
    local module_name=$(basename "$module_file" .json)
    local has_errors=0
    local has_warnings=0
    
    echo "Checking module: $module_name"
    
    # Check if operational_tiers exists
    if ! jq -e '.operational_tiers' "$module_file" >/dev/null 2>&1; then
        echo -e "  ${YELLOW}⚠️  No operational_tiers defined${NC}"
        has_warnings=1
        warnings=$((warnings + 1))
        return 1
    fi
    
    # Extract operational tiers
    local deployment_types=$(jq -r '.operational_tiers.deployment[]?' "$module_file" 2>/dev/null)
    local environments=$(jq -r '.operational_tiers.environments[]?' "$module_file" 2>/dev/null)
    local constraints=$(jq -r '.operational_tiers.constraints[]?' "$module_file" 2>/dev/null)
    
    # Validate deployment types
    if [[ -n "$deployment_types" ]]; then
        while IFS= read -r deployment; do
            if [[ -n "$deployment" ]] && ! contains_element "$deployment" "${VALID_DEPLOYMENT[@]}"; then
                echo -e "  ${RED}❌ Invalid deployment type: $deployment${NC}"
                has_errors=1
            fi
        done <<< "$deployment_types"
    else
        echo -e "  ${RED}❌ No deployment types specified${NC}"
        has_errors=1
    fi
    
    # Validate environments
    if [[ -n "$environments" ]]; then
        while IFS= read -r environment; do
            if [[ -n "$environment" ]] && ! contains_element "$environment" "${VALID_ENVIRONMENTS[@]}"; then
                echo -e "  ${RED}❌ Invalid environment: $environment${NC}"
                has_errors=1
            fi
        done <<< "$environments"
    else
        echo -e "  ${RED}❌ No environments specified${NC}"
        has_errors=1
    fi
    
    # Validate constraints (optional)
    if [[ -n "$constraints" ]]; then
        while IFS= read -r constraint; do
            if [[ -n "$constraint" ]] && ! contains_element "$constraint" "${VALID_CONSTRAINTS[@]}"; then
                echo -e "  ${RED}❌ Invalid constraint: $constraint${NC}"
                has_errors=1
            fi
        done <<< "$constraints"
    fi
    
    # Check for logical inconsistencies
    local deployment_array=($(jq -r '.operational_tiers.deployment[]?' "$module_file" 2>/dev/null))
    local environment_array=($(jq -r '.operational_tiers.environments[]?' "$module_file" 2>/dev/null))
    
    # Warn if production environment but only local deployment
    if contains_element "production" "${environment_array[@]}" && [[ "${#deployment_array[@]}" -eq 1 ]] && contains_element "local" "${deployment_array[@]}"; then
        echo -e "  ${YELLOW}⚠️  Production environment with only local deployment may not be appropriate${NC}"
        has_warnings=1
        warnings=$((warnings + 1))
    fi
    
    if [[ $has_errors -eq 0 ]]; then
        echo -e "  ${GREEN}✅ Valid operational tiers${NC}"
        return 0
    else
        return 1
    fi
}

# Find and validate all module files
echo "Searching for modules in: $MODULES_DIR"
echo

while IFS= read -r -d '' module_file; do
    total_modules=$((total_modules + 1))
    
    if validate_module_tiers "$module_file"; then
        valid_modules=$((valid_modules + 1))
    else
        invalid_modules=$((invalid_modules + 1))
    fi
    echo
done < <(find "$MODULES_DIR" -name "*.json" -type f -print0)

# Summary
echo "=================================================="
echo "Operational Tiers Validation Summary"
echo "=================================================="
echo "Total modules checked: $total_modules"
echo -e "Valid modules: ${GREEN}$valid_modules${NC}"
echo -e "Invalid modules: ${RED}$invalid_modules${NC}"
echo -e "Warnings: ${YELLOW}$warnings${NC}"

if [[ $invalid_modules -eq 0 ]]; then
    echo -e "\n${GREEN}🎉 All modules have valid operational tiers!${NC}"
    exit 0
else
    echo -e "\n${RED}❌ Some modules have invalid operational tiers${NC}"
    exit 1
fi
