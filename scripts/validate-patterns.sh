#!/bin/bash

# Validate custom operational tier patterns
# This script validates custom patterns against the schema and checks for conflicts

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
PATTERNS_DIR="$REPO_ROOT/patterns"
SCHEMA_FILE="$REPO_ROOT/schemas/custom-pattern.json"
OFFICIAL_PATTERNS="$REPO_ROOT/registry/patterns.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
total_patterns=0
valid_patterns=0
invalid_patterns=0
warnings=0

echo "🔍 Validating custom operational tier patterns..."
echo

# Check if required files exist
if [[ ! -f "$SCHEMA_FILE" ]]; then
    echo -e "${RED}❌ Custom pattern schema not found: $SCHEMA_FILE${NC}"
    exit 1
fi

if [[ ! -f "$OFFICIAL_PATTERNS" ]]; then
    echo -e "${YELLOW}⚠️  Official patterns file not found: $OFFICIAL_PATTERNS${NC}"
    warnings=$((warnings + 1))
fi

# Check if ajv-cli is available for JSON schema validation
if command -v ajv >/dev/null 2>&1; then
    USE_AJV=true
    echo -e "${BLUE}ℹ️  Using ajv-cli for schema validation${NC}"
else
    USE_AJV=false
    echo -e "${YELLOW}⚠️  ajv-cli not found, skipping schema validation${NC}"
    echo -e "${YELLOW}   Install with: npm install -g ajv-cli${NC}"
    warnings=$((warnings + 1))
fi

# Function to validate pattern against schema
validate_schema() {
    local pattern_file="$1"
    
    if [[ "$USE_AJV" == "true" ]]; then
        if ajv validate -s "$SCHEMA_FILE" -d "$pattern_file" >/dev/null 2>&1; then
            return 0
        else
            echo -e "  ${RED}❌ Schema validation failed${NC}"
            ajv validate -s "$SCHEMA_FILE" -d "$pattern_file" 2>&1 | sed 's/^/    /'
            return 1
        fi
    else
        # Basic JSON validation
        if jq empty "$pattern_file" >/dev/null 2>&1; then
            return 0
        else
            echo -e "  ${RED}❌ Invalid JSON format${NC}"
            return 1
        fi
    fi
}

# Function to check for slug conflicts
check_slug_conflicts() {
    local pattern_file="$1"
    local slug=$(jq -r '.slug' "$pattern_file" 2>/dev/null)
    
    if [[ "$slug" == "null" || -z "$slug" ]]; then
        echo -e "  ${RED}❌ Missing or invalid slug${NC}"
        return 1
    fi
    
    # Check against official patterns
    if [[ -f "$OFFICIAL_PATTERNS" ]]; then
        if jq -e ".patterns.official[\"$slug\"] or .patterns.community[\"$slug\"]" "$OFFICIAL_PATTERNS" >/dev/null 2>&1; then
            echo -e "  ${RED}❌ Slug '$slug' conflicts with official pattern${NC}"
            return 1
        fi
    fi
    
    # Check against other custom patterns
    local conflicts=0
    while IFS= read -r -d '' other_pattern; do
        if [[ "$other_pattern" != "$pattern_file" ]]; then
            local other_slug=$(jq -r '.slug' "$other_pattern" 2>/dev/null)
            if [[ "$other_slug" == "$slug" ]]; then
                echo -e "  ${RED}❌ Slug '$slug' conflicts with $(basename "$other_pattern")${NC}"
                conflicts=$((conflicts + 1))
            fi
        fi
    done < <(find "$PATTERNS_DIR" -name "*.json" -type f -print0)
    
    return $conflicts
}

# Function to validate operational tiers consistency
validate_operational_tiers() {
    local pattern_file="$1"
    local has_errors=0
    
    # Extract operational tiers
    local deployment_types=$(jq -r '.operational_tiers.deployment[]?' "$pattern_file" 2>/dev/null)
    local environments=$(jq -r '.operational_tiers.environments[]?' "$pattern_file" 2>/dev/null)
    local constraints=$(jq -r '.operational_tiers.constraints[]?' "$pattern_file" 2>/dev/null)
    
    # Check for logical inconsistencies
    local deployment_array=($(jq -r '.operational_tiers.deployment[]?' "$pattern_file" 2>/dev/null))
    local environment_array=($(jq -r '.operational_tiers.environments[]?' "$pattern_file" 2>/dev/null))
    local constraint_array=($(jq -r '.operational_tiers.constraints[]?' "$pattern_file" 2>/dev/null))
    
    # Warn about potential issues
    
    # Production with only local deployment
    if [[ " ${environment_array[*]} " =~ " production " ]] && [[ ${#deployment_array[@]} -eq 1 ]] && [[ " ${deployment_array[*]} " =~ " local " ]]; then
        echo -e "  ${YELLOW}⚠️  Production environment with only local deployment${NC}"
        warnings=$((warnings + 1))
    fi
    
    # GPU constraints without appropriate deployment
    if [[ " ${constraint_array[*]} " =~ " gpu_required " ]] && ! [[ " ${deployment_array[*]} " =~ " cloud " ]] && ! [[ " ${deployment_array[*]} " =~ " bare-metal " ]]; then
        echo -e "  ${YELLOW}⚠️  GPU required but no suitable deployment types${NC}"
        warnings=$((warnings + 1))
    fi
    
    # Security compliance without production
    if [[ " ${constraint_array[*]} " =~ " security_compliance " ]] && ! [[ " ${environment_array[*]} " =~ " production " ]]; then
        echo -e "  ${YELLOW}⚠️  Security compliance constraint but no production environment${NC}"
        warnings=$((warnings + 1))
    fi
    
    return $has_errors
}

# Function to validate a single pattern
validate_pattern() {
    local pattern_file="$1"
    local pattern_name=$(basename "$pattern_file" .json)
    local has_errors=0
    
    echo "Checking pattern: $pattern_name"
    
    # Schema validation
    if ! validate_schema "$pattern_file"; then
        has_errors=1
    fi
    
    # Slug conflict check
    if ! check_slug_conflicts "$pattern_file"; then
        has_errors=1
    fi
    
    # Operational tiers validation
    validate_operational_tiers "$pattern_file"
    
    # Check required fields manually (backup for when ajv is not available)
    local name=$(jq -r '.name' "$pattern_file" 2>/dev/null)
    local description=$(jq -r '.description' "$pattern_file" 2>/dev/null)
    
    if [[ "$name" == "null" || -z "$name" ]]; then
        echo -e "  ${RED}❌ Missing required field: name${NC}"
        has_errors=1
    fi
    
    if [[ "$description" == "null" || -z "$description" ]]; then
        echo -e "  ${RED}❌ Missing required field: description${NC}"
        has_errors=1
    fi
    
    if [[ $has_errors -eq 0 ]]; then
        echo -e "  ${GREEN}✅ Valid custom pattern${NC}"
        return 0
    else
        return 1
    fi
}

# Find and validate all pattern files
echo "Searching for patterns in: $PATTERNS_DIR"
echo

if [[ -d "$PATTERNS_DIR" ]]; then
    while IFS= read -r -d '' pattern_file; do
        total_patterns=$((total_patterns + 1))
        
        if validate_pattern "$pattern_file"; then
            valid_patterns=$((valid_patterns + 1))
        else
            invalid_patterns=$((invalid_patterns + 1))
        fi
        echo
    done < <(find "$PATTERNS_DIR" -name "*.json" -type f -print0)
else
    echo -e "${YELLOW}⚠️  Patterns directory not found: $PATTERNS_DIR${NC}"
    warnings=$((warnings + 1))
fi

# Summary
echo "=================================================="
echo "Custom Pattern Validation Summary"
echo "=================================================="
echo "Total patterns checked: $total_patterns"
echo -e "Valid patterns: ${GREEN}$valid_patterns${NC}"
echo -e "Invalid patterns: ${RED}$invalid_patterns${NC}"
echo -e "Warnings: ${YELLOW}$warnings${NC}"

if [[ $total_patterns -eq 0 ]]; then
    echo -e "\n${BLUE}ℹ️  No custom patterns found${NC}"
    exit 0
elif [[ $invalid_patterns -eq 0 ]]; then
    echo -e "\n${GREEN}🎉 All custom patterns are valid!${NC}"
    exit 0
else
    echo -e "\n${RED}❌ Some custom patterns have issues${NC}"
    exit 1
fi
