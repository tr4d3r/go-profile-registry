#!/bin/bash
set -e

echo "🔍 Validating go-profile-registry setup..."

# Check required directories
if [ ! -d "modules" ]; then
    echo "❌ modules/ directory not found"
    exit 1
fi

if [ ! -d "scripts" ]; then
    echo "❌ scripts/ directory not found"
    exit 1
fi

# Check if we have any modules
MODULE_COUNT=$(find modules -name "*.json" | wc -l)
if [ "$MODULE_COUNT" -eq 0 ]; then
    echo "❌ No modules found in modules/ directory"
    exit 1
fi

echo "✅ Found $MODULE_COUNT modules"

# Validate JSON syntax
echo "🔍 Validating JSON syntax..."
for json_file in $(find modules -name "*.json"); do
    if ! jq empty "$json_file" 2>/dev/null; then
        echo "❌ Invalid JSON in: $json_file"
        exit 1
    fi
done

echo "✅ All JSON files are valid"

# Check if registry builder exists
if [ ! -f "scripts/registry-builder/main.go" ]; then
    echo "❌ Registry builder not found"
    exit 1
fi

echo "✅ Registry builder found"

# Test build
echo "🔧 Testing registry build..."
if [ -x "scripts/build-registry.sh" ]; then
    ./scripts/build-registry.sh
    echo "✅ Registry build successful"
else
    echo "❌ Build script not executable or not found"
    exit 1
fi

# Check generated files
if [ ! -f "registry/index.json" ]; then
    echo "❌ Registry index not generated"
    exit 1
fi

if [ ! -f "registry/categories.json" ]; then
    echo "❌ Categories file not generated"
    exit 1
fi

echo "✅ Registry files generated successfully"

# Validate generated registry files
echo "🔍 Validating generated registry files..."
for json_file in $(find registry -name "*.json"); do
    if ! jq empty "$json_file" 2>/dev/null; then
        echo "❌ Invalid JSON in generated file: $json_file"
        exit 1
    fi
done

echo "✅ All generated registry files are valid"

echo ""
echo "🎉 Registry validation completed successfully!"
echo ""
echo "📊 Summary:"
echo "  Modules: $MODULE_COUNT"
echo "  Categories: $(jq -r '.categories | length' registry/categories.json)"
echo "  Registry size: $(du -sh registry | cut -f1)"
