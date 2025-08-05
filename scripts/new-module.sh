#!/bin/bash
set -e

# Script to create a new module from template

MODULE_NAME=""
CATEGORY=""
DESCRIPTION=""
AUTHOR=""

usage() {
    echo "Usage: $0 --name MODULE_NAME --category CATEGORY --description DESCRIPTION [--author AUTHOR]"
    echo ""
    echo "Categories: development, ai-tools, enterprise, devops, platform"
    echo ""
    echo "Example:"
    echo "  $0 --name python --category development --description 'Python development tools' --author 'John Doe <john@example.com>'"
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --name)
            MODULE_NAME="$2"
            shift 2
            ;;
        --category)
            CATEGORY="$2"
            shift 2
            ;;
        --description)
            DESCRIPTION="$2"
            shift 2
            ;;
        --author)
            AUTHOR="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Validate required parameters
if [[ -z "$MODULE_NAME" || -z "$CATEGORY" || -z "$DESCRIPTION" ]]; then
    echo "❌ Missing required parameters"
    usage
fi

# Validate category
case $CATEGORY in
    development|ai-tools|enterprise|devops|platform)
        ;;
    *)
        echo "❌ Invalid category: $CATEGORY"
        echo "   Valid categories: development, ai-tools, enterprise, devops, platform"
        exit 1
        ;;
esac

# Validate module name (lowercase, alphanumeric, hyphens only)
if [[ ! "$MODULE_NAME" =~ ^[a-z0-9-]+$ ]]; then
    echo "❌ Invalid module name: $MODULE_NAME"
    echo "   Module names must be lowercase, alphanumeric, and hyphens only"
    exit 1
fi

# Create category directory if it doesn't exist
CATEGORY_DIR="modules/$CATEGORY"
mkdir -p "$CATEGORY_DIR"

# Module file path
MODULE_FILE="$CATEGORY_DIR/$MODULE_NAME.json"

# Check if module already exists
if [[ -f "$MODULE_FILE" ]]; then
    echo "❌ Module already exists: $MODULE_FILE"
    exit 1
fi

# Generate module template
echo "📝 Creating module: $MODULE_FILE"

# Build JSON template
JSON_TEMPLATE='{
  "name": "'"$MODULE_NAME"'",
  "version": "1.0.0",
  "description": "'"$DESCRIPTION"'",
  "category": "'"$CATEGORY"'",
  "platforms": ["darwin", "linux", "windows"],
  "shells": ["bash", "zsh", "fish", "powershell"],
  "environment": [],
  "aliases": [],
  "functions": [],
  "path": [],
  "files": [],
  "checks": []
}'

# Add author if provided
if [[ -n "$AUTHOR" ]]; then
    JSON_TEMPLATE=$(echo "$JSON_TEMPLATE" | jq ". + {\"author\": \"$AUTHOR\"}")
fi

# Write JSON to file with proper formatting
echo "$JSON_TEMPLATE" | jq '.' > "$MODULE_FILE"

echo "✅ Module created successfully!"
echo ""
echo "📄 File: $MODULE_FILE"
echo "🔧 Next steps:"
echo "   1. Edit $MODULE_FILE to add your configuration"
echo "   2. Run 'make validate' to check syntax"
echo "   3. Run 'make build-registry' to update registry"
echo "   4. Test with 'make test'"
echo ""
echo "📖 Documentation:"
echo "   - See existing modules in $CATEGORY_DIR/ for examples"
echo "   - Read REMOTE_MODULES.md for module format details"
echo "   - Check README.md for contribution guidelines"
