# Operational Tiers

The go-profile registry uses operational tier classifications to help users understand where and how different modules can be deployed. This metadata enables better filtering, recommendations, and deployment planning.

## Overview

Operational tiers consist of three main dimensions:

1. **Deployment Types** - Where the module can be deployed
2. **Environment Compatibility** - Which operational environments support the module  
3. **Constraints** - Special requirements or characteristics

## Deployment Types

### `local`
- **Description**: Local development environments on personal machines
- **Use Cases**: Development, testing, prototyping, IDE integration
- **Examples**: Go toolchain, Node.js, Python interpreters

### `container`
- **Description**: Containerized environments using Docker, Kubernetes, etc.
- **Use Cases**: Microservices, scalable deployment, process isolation
- **Examples**: Application runtimes, database clients, monitoring agents

### `cloud`
- **Description**: Cloud-native services and managed platforms
- **Use Cases**: Managed services, serverless functions, auto-scaling applications
- **Examples**: Cloud CLI tools, serverless frameworks, managed database connectors

### `bare-metal`
- **Description**: Direct deployment on physical hardware
- **Use Cases**: High-performance computing, specialized hardware, legacy systems
- **Examples**: System utilities, hardware-specific drivers, performance monitoring

### `hybrid`
- **Description**: Works seamlessly across multiple deployment types
- **Use Cases**: Flexible deployment strategies, migration scenarios
- **Examples**: Universal CLI tools, cross-platform utilities

## Environment Compatibility

### `development`
- **Characteristics**: Rapid iteration, debugging tools, relaxed security
- **Purpose**: Active development and testing
- **Examples**: Debug builds, development servers, testing frameworks

### `staging`
- **Characteristics**: Production-like setup, integration testing, performance validation
- **Purpose**: Pre-production validation and testing
- **Examples**: Load testing tools, integration test suites

### `production`
- **Characteristics**: High availability, security hardened, comprehensive monitoring
- **Purpose**: Live operational environments
- **Examples**: Production monitoring, security tools, performance optimization

## Constraints

### Network Requirements
- **`network_required`**: Must have network connectivity to function
- **`network_optional`**: Can work offline or with limited connectivity

### Hardware Requirements
- **`gpu_required`**: Requires GPU hardware for core functionality
- **`gpu_optional`**: Can utilize GPU acceleration if available
- **`high_memory`**: Requires significant memory resources (>4GB)
- **`high_cpu`**: Requires significant CPU resources (>2 cores)

### Access Requirements
- **`privileged_access`**: Requires elevated system permissions (root/admin)
- **`security_compliance`**: Implements specific security/compliance requirements

### System Requirements
- **`platform_specific`**: Functionality varies significantly by operating system
- **`persistent_storage`**: Requires persistent storage for data/configuration

## Usage in Modules

Include operational tiers in your module definition:

```json
{
  "name": "example-module",
  "version": "1.0.0",
  "description": "Example module",
  "category": "development",
  "operational_tiers": {
    "deployment": ["local", "container"],
    "environments": ["development", "staging"],
    "constraints": ["network_optional"]
  }
}
```

## Filtering and Recommendations

The go-profile CLI can use operational tiers to:

- **Filter modules** by deployment target: `go-profile list --deployment container`
- **Recommend modules** based on environment: `go-profile recommend --env production`
- **Validate compatibility** before installation
- **Show warnings** for constraint mismatches

## Best Practices

### For Module Authors
1. **Be specific** - Include all relevant deployment types and environments
2. **Document constraints** - Clearly specify any special requirements
3. **Test across tiers** - Validate your module works in specified environments
4. **Update as needed** - Revise tiers when module capabilities change

### For Users
1. **Check compatibility** - Review operational tiers before installing modules
2. **Plan deployments** - Use tier information for deployment planning
3. **Report issues** - Notify maintainers if modules don't work in specified tiers

## Examples by Category

### Development Tools
```json
"operational_tiers": {
  "deployment": ["local", "container", "cloud"],
  "environments": ["development", "staging", "production"],
  "constraints": ["network_optional"]
}
```

### AI/ML Tools
```json
"operational_tiers": {
  "deployment": ["local", "container", "cloud"],
  "environments": ["development", "staging", "production"],
  "constraints": ["gpu_optional", "network_required", "high_memory"]
}
```

### DevOps Tools
```json
"operational_tiers": {
  "deployment": ["local", "container", "cloud", "bare-metal"],
  "environments": ["development", "staging", "production"],
  "constraints": ["network_required", "privileged_access"]
}
```

### Enterprise Tools
```json
"operational_tiers": {
  "deployment": ["container", "cloud", "hybrid"],
  "environments": ["staging", "production"],
  "constraints": ["network_required", "security_compliance", "privileged_access"]
}
```
