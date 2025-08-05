# go-profile-registry

Community module registry for [go-profile](https://github.com/tr4d3r/go-profile) - a cross-platform shell configuration management system.

## 🎯 Overview

This registry provides a collection of pre-built configuration modules for different development environments, tools, and workflows. Modules are automatically validated and built into a structured registry that can be consumed by the go-profile CLI tool.

## 📦 Available Modules

- **Development**: Programming language environments (Go, Python, Node.js, etc.)
- **AI Tools**: AI development and machine learning tools
- **Enterprise**: Enterprise development and deployment tools  
- **DevOps**: CI/CD, containerization, and infrastructure tools
- **Platform**: Cloud platform tools and configurations

## 🚀 Quick Start

### Using Modules

```bash
# Install go-profile CLI tool first
go install github.com/tr4d3r/go-profile@latest

# List available modules from registry
go-profile list --remote

# Install a module from the registry
go-profile install go
```

### Contributing Modules

1. **Create a new module**:

   ```bash
   make new-module --name your-module --category development --description "Your module description"
   ```

2. **Edit the module file**:

   ```bash
   # Edit modules/development/your-module.json
   # Add environment variables, aliases, functions, etc.
   ```

3. **Validate and test**:

   ```bash
   make validate
   make test
   ```

4. **Submit a pull request** with your new module

## 🛠️ Development

### Prerequisites

- Go 1.21+
- jq (for JSON validation)
- Make

### Building the Registry

```bash
# Build registry from all modules
make build-registry

# Validate all modules
make validate

# Run full test suite
make test

# View registry statistics
make stats
```

### Module Format

Modules are JSON files with the following structure:

```json
{
  "name": "module-name",
  "version": "1.0.0",
  "description": "Module description",
  "category": "development",
  "platforms": ["darwin", "linux", "windows"],
  "shells": ["bash", "zsh", "fish", "powershell"],
  "environment": [
    {
      "name": "VARIABLE_NAME",
      "value": "variable_value",
      "description": "What this variable does"
    }
  ],
  "aliases": [
    {
      "name": "alias_name",
      "command": "actual_command",
      "description": "What this alias does"
    }
  ],
  "functions": [
    {
      "name": "function_name",
      "script": "function body",
      "description": "What this function does"
    }
  ],
  "path": [
    {
      "path": "/path/to/add",
      "description": "Why this path is needed"
    }
  ],
  "files": [
    {
      "path": "~/.config/tool/config",
      "content": "file content",
      "description": "Configuration file"
    }
  ],
  "checks": [
    {
      "command": "command_to_check",
      "description": "What this checks"
    }
  ]
}
```

### Available Make Targets

- `make build-registry` - Build registry from modules
- `make validate` - Validate all module JSON files
- `make test` - Run validation and build tests
- `make stats` - Show registry statistics
- `make new-module` - Create a new module from template
- `make clean` - Clean generated files
- `make help` - Show all available targets

## 📁 Repository Structure

```text
go-profile-registry/
├── modules/                    # Module definitions
│   ├── development/           # Development tools
│   ├── ai-tools/             # AI and ML tools
│   ├── enterprise/           # Enterprise tools
│   ├── devops/               # DevOps tools
│   └── platform/             # Platform tools
├── registry/                  # Generated registry files
│   ├── index.json            # Main registry index
│   ├── categories.json       # Category definitions
│   └── modules/              # Individual module metadata
├── scripts/                   # Build and utility scripts
│   ├── registry-builder/     # Go application for building registry
│   ├── build-registry.sh     # Main build script
│   └── new-module.sh         # Module creation script
└── .github/workflows/        # CI/CD automation
```

## 🤝 Contributing

1. Fork this repository
2. Create a feature branch (`git checkout -b feature/your-module`)
3. Add your module using `make new-module`
4. Validate with `make test`
5. Commit your changes (`git commit -am 'Add your-module'`)
6. Push to the branch (`git push origin feature/your-module`)
7. Create a Pull Request

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built for the [go-profile](https://github.com/tr4d3r/go-profile) ecosystem
- Inspired by package managers and module registries
- Community-driven module contributions
