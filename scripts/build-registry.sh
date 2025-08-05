#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
MODULES_DIR="$ROOT_DIR/modules"
REGISTRY_DIR="$ROOT_DIR/registry"

echo "🔨 Building registry from modules..."

# Ensure we have the required directories
if [ ! -d "$MODULES_DIR" ]; then
    echo "❌ Modules directory not found: $MODULES_DIR"
    exit 1
fi

# Create registry directories
mkdir -p "$REGISTRY_DIR/versions"

# Build the registry builder if it doesn't exist
BUILDER_DIR="$SCRIPT_DIR/registry-builder"
if [ ! -f "$BUILDER_DIR/registry-builder" ] || [ "$BUILDER_DIR/main.go" -nt "$BUILDER_DIR/registry-builder" ]; then
    echo "🔧 Building registry builder..."
    cd "$BUILDER_DIR"
    go build -o registry-builder main.go
    cd "$ROOT_DIR"
fi

# Generate registry files
echo "📋 Generating registry metadata..."
"$BUILDER_DIR/registry-builder" \
  --modules-dir "$MODULES_DIR" \
  --registry-dir "$REGISTRY_DIR" \
  --base-url "https://registry.go-profile.dev"

echo "✅ Registry build complete!"
echo "📁 Generated files:"
find "$REGISTRY_DIR" -name "*.json" | sort

# Validate generated JSON files
echo "🔍 Validating generated registry files..."
for json_file in $(find "$REGISTRY_DIR" -name "*.json"); do
    if ! jq empty "$json_file" 2>/dev/null; then
        echo "❌ Invalid JSON in: $json_file"
        exit 1
    fi
done

echo "✅ All registry files are valid JSON"
