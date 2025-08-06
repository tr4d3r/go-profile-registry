#!/bin/bash

# Apply operational tier patterns to modules
# This script helps apply predefined patterns to modules

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
MODULES_DIR="$REPO_ROOT/modules"
PATTERNS_DIR="$REPO_ROOT/patterns"
OFFICIAL_PATTERNS="$REPO_ROOT/registry/patterns.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Apply operational tier patterns to modules"
    echo ""
    echo "Options:"
    echo "  -l, --list              List available patterns"
    echo "  -p, --pattern PATTERN   Apply specific pattern"
    echo "  -m, --module MODULE     Target specific module"
    echo "  -a, --apply-all         Apply patterns to all compatible modules"
    echo "  -d, --dry-run           Show what would be changed without applying"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --list                           # List all available patterns"
    echo "  $0 --pattern web-development        # Show details for web-development pattern"
    echo "  $0 --pattern web-development --module go --dry-run  # Preview applying pattern to go module"
    echo "  $0 --pattern web-development --module go            # Apply pattern to go module"
}

# Function to list all available patterns
list_patterns() {
    echo -e "${BLUE}📋 Available Operational Tier Patterns${NC}"
    echo "======================================"
    
    # Official patterns
    if [[ -f "$OFFICIAL_PATTERNS" ]]; then
        echo -e "\n${GREEN}Official Patterns:${NC}"
        jq -r '.patterns.official | to_entries[] | "  \(.key) - \(.value.name)"' "$OFFICIAL_PATTERNS" 2>/dev/null || echo "  No official patterns found"
        
        echo -e "\n${BLUE}Community Patterns:${NC}"
        jq -r '.patterns.community | to_entries[] | "  \(.key) - \(.value.name)"' "$OFFICIAL_PATTERNS" 2>/dev/null || echo "  No community patterns found"
    fi
    
    # Custom patterns
    if [[ -d "$PATTERNS_DIR" ]]; then
        echo -e "\n${YELLOW}Custom Patterns:${NC}"
        local found_custom=false
        while IFS= read -r -d '' pattern_file; do
            local slug=$(jq -r '.slug' "$pattern_file" 2>/dev/null)
            local name=$(jq -r '.name' "$pattern_file" 2>/dev/null)
            if [[ "$slug" != "null" && "$name" != "null" ]]; then
                echo "  $slug - $name"
                found_custom=true
            fi
        done < <(find "$PATTERNS_DIR" -name "*.json" -type f -print0)
        
        if [[ "$found_custom" == "false" ]]; then
            echo "  No custom patterns found"
        fi
    fi
}

# Function to show pattern details
show_pattern_details() {
    local pattern_slug="$1"
    local found=false
    
    # Check official patterns
    if [[ -f "$OFFICIAL_PATTERNS" ]]; then
        if jq -e ".patterns.official[\"$pattern_slug\"]" "$OFFICIAL_PATTERNS" >/dev/null 2>&1; then
            echo -e "${GREEN}📦 Official Pattern: $pattern_slug${NC}"
            echo "=================================="
            jq -r ".patterns.official[\"$pattern_slug\"] | \"Name: \\(.name)\\nDescription: \\(.description)\\nRecommended for: \\(.recommended_for | join(\\\", \\\"))\\nUse cases: \\(.use_cases | join(\\\", \\\"))\"" "$OFFICIAL_PATTERNS"
            echo ""
            echo "Operational Tiers:"
            jq -r ".patterns.official[\"$pattern_slug\"].operational_tiers | \"  Deployment: \\(.deployment | join(\\\", \\\"))\\n  Environments: \\(.environments | join(\\\", \\\"))\\n  Constraints: \\(.constraints // [] | join(\\\", \\\"))\"" "$OFFICIAL_PATTERNS"
            found=true
        elif jq -e ".patterns.community[\"$pattern_slug\"]" "$OFFICIAL_PATTERNS" >/dev/null 2>&1; then
            echo -e "${BLUE}🌟 Community Pattern: $pattern_slug${NC}"
            echo "================================="
            jq -r ".patterns.community[\"$pattern_slug\"] | \"Name: \\(.name)\\nDescription: \\(.description)\\nAuthor: \\(.author)\\nVotes: \\(.votes)\\nRecommended for: \\(.recommended_for | join(\\\", \\\"))\"" "$OFFICIAL_PATTERNS"
            echo ""
            echo "Operational Tiers:"
            jq -r ".patterns.community[\"$pattern_slug\"].operational_tiers | \"  Deployment: \\(.deployment | join(\\\", \\\"))\\n  Environments: \\(.environments | join(\\\", \\\"))\\n  Constraints: \\(.constraints // [] | join(\\\", \\\"))\"" "$OFFICIAL_PATTERNS"
            found=true
        fi
    fi
    
    # Check custom patterns
    if [[ -d "$PATTERNS_DIR" && "$found" == "false" ]]; then
        while IFS= read -r -d '' pattern_file; do
            local slug=$(jq -r '.slug' "$pattern_file" 2>/dev/null)
            if [[ "$slug" == "$pattern_slug" ]]; then
                echo -e "${YELLOW}🔧 Custom Pattern: $pattern_slug${NC}"
                echo "=============================="
                jq -r '"Name: \(.name)\nDescription: \(.description)\nVersion: \(.version)\nAuthor: \(.author.name // "Unknown")\nRecommended for: \(.recommended_for | join(", "))"' "$pattern_file"
                echo ""
                echo "Operational Tiers:"
                jq -r '.operational_tiers | "  Deployment: \(.deployment | join(", "))\n  Environments: \(.environments | join(", "))\n  Constraints: \(.constraints // [] | join(", "))"' "$pattern_file"
                
                if jq -e '.examples' "$pattern_file" >/dev/null 2>&1; then
                    echo ""
                    echo "Example modules:"
                    jq -r '.examples[] | "  - \(.module_name): \(.description)"' "$pattern_file"
                fi
                
                found=true
                break
            fi
        done < <(find "$PATTERNS_DIR" -name "*.json" -type f -print0)
    fi
    
    if [[ "$found" == "false" ]]; then
        echo -e "${RED}❌ Pattern '$pattern_slug' not found${NC}"
        return 1
    fi
}

# Function to get pattern operational tiers
get_pattern_tiers() {
    local pattern_slug="$1"
    local tiers=""
    
    # Check official patterns
    if [[ -f "$OFFICIAL_PATTERNS" ]]; then
        if jq -e ".patterns.official[\"$pattern_slug\"]" "$OFFICIAL_PATTERNS" >/dev/null 2>&1; then
            tiers=$(jq -c ".patterns.official[\"$pattern_slug\"].operational_tiers" "$OFFICIAL_PATTERNS")
        elif jq -e ".patterns.community[\"$pattern_slug\"]" "$OFFICIAL_PATTERNS" >/dev/null 2>&1; then
            tiers=$(jq -c ".patterns.community[\"$pattern_slug\"].operational_tiers" "$OFFICIAL_PATTERNS")
        fi
    fi
    
    # Check custom patterns
    if [[ -z "$tiers" && -d "$PATTERNS_DIR" ]]; then
        while IFS= read -r -d '' pattern_file; do
            local slug=$(jq -r '.slug' "$pattern_file" 2>/dev/null)
            if [[ "$slug" == "$pattern_slug" ]]; then
                tiers=$(jq -c '.operational_tiers' "$pattern_file")
                break
            fi
        done < <(find "$PATTERNS_DIR" -name "*.json" -type f -print0)
    fi
    
    echo "$tiers"
}

# Function to apply pattern to module
apply_pattern_to_module() {
    local pattern_slug="$1"
    local module_name="$2"
    local dry_run="$3"
    
    local module_file="$MODULES_DIR/*/$module_name.json"
    local found_module=""
    
    # Find the module file
    for file in $module_file; do
        if [[ -f "$file" ]]; then
            found_module="$file"
            break
        fi
    done
    
    if [[ -z "$found_module" ]]; then
        echo -e "${RED}❌ Module '$module_name' not found${NC}"
        return 1
    fi
    
    # Get pattern operational tiers
    local pattern_tiers=$(get_pattern_tiers "$pattern_slug")
    if [[ -z "$pattern_tiers" || "$pattern_tiers" == "null" ]]; then
        echo -e "${RED}❌ Pattern '$pattern_slug' not found or has no operational tiers${NC}"
        return 1
    fi
    
    echo -e "${BLUE}📦 Applying pattern '$pattern_slug' to module '$module_name'${NC}"
    
    if [[ "$dry_run" == "true" ]]; then
        echo -e "${YELLOW}🔍 DRY RUN - No changes will be made${NC}"
        echo ""
        echo "Current operational tiers:"
        if jq -e '.operational_tiers' "$found_module" >/dev/null 2>&1; then
            jq -r '.operational_tiers | "  Deployment: \(.deployment | join(", "))\n  Environments: \(.environments | join(", "))\n  Constraints: \(.constraints // [] | join(", "))"' "$found_module"
        else
            echo "  None defined"
        fi
        
        echo ""
        echo "Would apply these operational tiers:"
        echo "$pattern_tiers" | jq -r '"  Deployment: \(.deployment | join(", "))\n  Environments: \(.environments | join(", "))\n  Constraints: \(.constraints // [] | join(", "))"'
    else
        # Create backup
        cp "$found_module" "$found_module.backup"
        
        # Apply the pattern
        local temp_file=$(mktemp)
        jq ".operational_tiers = $pattern_tiers" "$found_module" > "$temp_file"
        mv "$temp_file" "$found_module"
        
        echo -e "${GREEN}✅ Pattern applied successfully${NC}"
        echo "Backup created: $found_module.backup"
    fi
}

# Parse command line arguments
DRY_RUN=false
PATTERN=""
MODULE=""
APPLY_ALL=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -l|--list)
            list_patterns
            exit 0
            ;;
        -p|--pattern)
            PATTERN="$2"
            shift 2
            ;;
        -m|--module)
            MODULE="$2"
            shift 2
            ;;
        -a|--apply-all)
            APPLY_ALL=true
            shift
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Unknown option: $1${NC}"
            show_usage
            exit 1
            ;;
    esac
done

# Handle different modes
if [[ -n "$PATTERN" && -z "$MODULE" && "$APPLY_ALL" == "false" ]]; then
    # Show pattern details
    show_pattern_details "$PATTERN"
elif [[ -n "$PATTERN" && -n "$MODULE" ]]; then
    # Apply pattern to specific module
    apply_pattern_to_module "$PATTERN" "$MODULE" "$DRY_RUN"
elif [[ -n "$PATTERN" && "$APPLY_ALL" == "true" ]]; then
    echo -e "${YELLOW}⚠️  Apply-all functionality not yet implemented${NC}"
    exit 1
else
    echo -e "${RED}❌ Invalid arguments${NC}"
    show_usage
    exit 1
fi
