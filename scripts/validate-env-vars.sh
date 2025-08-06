#!/bin/bash

# Environment Variables Validation Script
# Validates that environment variables in modules follow the defined standards

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SCHEMAS_DIR="$PROJECT_ROOT/schemas"
MODULES_DIR="$PROJECT_ROOT/modules"
DOCS_DIR="$PROJECT_ROOT/docs"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
TOTAL_MODULES=0
VALID_MODULES=0
TOTAL_ENVVARS=0
VALID_ENVVARS=0

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

validate_env_var_name() {
    local name="$1"
    
    # Check if name matches pattern: starts with letter, contains only uppercase letters, numbers, and underscores
    if [[ ! "$name" =~ ^[A-Z][A-Z0-9_]*$ ]]; then
        return 1
    fi
    
    # Check if name doesn't start with number
    if [[ "$name" =~ ^[0-9] ]]; then
        return 1
    fi
    
    return 0
}

validate_env_var_schema() {
    local env_var="$1"
    local module_file="$2"
    local issues=""
    
    # Extract fields
    local name=$(echo "$env_var" | jq -r '.name // empty')
    local value=$(echo "$env_var" | jq -r '.value // empty')
    local export=$(echo "$env_var" | jq -r '.export // true')
    local description=$(echo "$env_var" | jq -r '.description // empty')
    local required=$(echo "$env_var" | jq -r '.required // false')
    local sensitive=$(echo "$env_var" | jq -r '.sensitive // false')
    
    # Validate required fields
    if [[ -z "$name" ]]; then
        issues+="Missing 'name' field; "
    elif ! validate_env_var_name "$name"; then
        issues+="Invalid name format '$name' (must be UPPER_CASE with underscores); "
    fi
    
    if [[ -z "$value" && "$required" == "true" ]]; then
        issues+="Missing 'value' field for required variable; "
    fi
    
    # Check for description on non-obvious variables
    if [[ -z "$description" && ! "$name" =~ ^(HOME|PWD|PATH|LANG|LC_ALL|TERM)$ ]]; then
        issues+="Missing 'description' field for '$name'; "
    fi
    
    # Check export field type
    if [[ "$export" != "true" && "$export" != "false" ]]; then
        issues+="Invalid 'export' field (must be boolean); "
    fi
    
    # Check required field type
    if [[ "$required" != "true" && "$required" != "false" ]]; then
        issues+="Invalid 'required' field (must be boolean); "
    fi
    
    # Check sensitive field type
    if [[ "$sensitive" != "true" && "$sensitive" != "false" ]]; then
        issues+="Invalid 'sensitive' field (must be boolean); "
    fi
    
    # Warn about sensitive variables with default values
    if [[ "$sensitive" == "true" && -n "$value" ]]; then
        issues+="Sensitive variable should not have default value; "
    fi
    
    if [[ -n "$issues" ]]; then
        log_error "  Variable '$name': $issues"
        return 1
    fi
    
    return 0
}

validate_module() {
    local module_file="$1"
    local module_name=$(basename "$module_file" .json)
    local valid=true
    
    log_info "Validating module: $module_name"
    
    # Check if file exists and is valid JSON
    if [[ ! -f "$module_file" ]]; then
        log_error "  Module file not found: $module_file"
        return 1
    fi
    
    if ! jq empty "$module_file" 2>/dev/null; then
        log_error "  Invalid JSON in module file: $module_file"
        return 1
    fi
    
    # Extract environment variables
    local env_vars=$(jq -c '.environment[]?' "$module_file" 2>/dev/null)
    
    if [[ -z "$env_vars" ]]; then
        log_warning "  No environment variables found in module"
        return 0
    fi
    
    # Validate each environment variable
    while IFS= read -r env_var; do
        TOTAL_ENVVARS=$((TOTAL_ENVVARS + 1))
        if validate_env_var_schema "$env_var" "$module_file"; then
            VALID_ENVVARS=$((VALID_ENVVARS + 1))
        else
            valid=false
        fi
    done <<< "$env_vars"
    
    if $valid; then
        log_success "  Module validation passed"
        return 0
    else
        log_error "  Module validation failed"
        return 1
    fi
}

main() {
    log_info "Starting environment variables validation"
    log_info "Project root: $PROJECT_ROOT"
    
    # Check if required tools are available
    if ! command -v jq &> /dev/null; then
        log_error "jq is required but not installed"
        exit 1
    fi
    
    # Find all module files
    local module_files=()
    while IFS= read -r -d '' file; do
        module_files+=("$file")
    done < <(find "$MODULES_DIR" -name "*.json" -type f -print0 2>/dev/null)
    
    if [[ ${#module_files[@]} -eq 0 ]]; then
        log_warning "No module files found in $MODULES_DIR"
        exit 0
    fi
    
    log_info "Found ${#module_files[@]} module file(s)"
    
    # Validate each module
    for module_file in "${module_files[@]}"; do
        TOTAL_MODULES=$((TOTAL_MODULES + 1))
        if validate_module "$module_file"; then
            VALID_MODULES=$((VALID_MODULES + 1))
        fi
    done
    
    # Print summary
    echo
    log_info "Validation Summary:"
    log_info "  Total modules: $TOTAL_MODULES"
    log_info "  Valid modules: $VALID_MODULES"
    log_info "  Total environment variables: $TOTAL_ENVVARS"
    log_info "  Valid environment variables: $VALID_ENVVARS"
    
    if [[ $VALID_MODULES -eq $TOTAL_MODULES && $VALID_ENVVARS -eq $TOTAL_ENVVARS ]]; then
        log_success "All validations passed!"
        exit 0
    else
        log_error "Validation failed! Please fix the issues above."
        exit 1
    fi
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
