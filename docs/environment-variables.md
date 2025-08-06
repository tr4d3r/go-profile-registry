# Standard Environment Variables

This document defines the standard set of supported environment variables for go-profile modules.

## Core Environment Variables

These are the fundamental environment variables that should be supported across all relevant modules:

### Development Tools

| Variable | Purpose | Example Value | Required Export |
|----------|---------|---------------|----------------|
| `EDITOR` | Default text editor | `code --wait`, `vim`, `nano` | Yes |
| `PAGER` | Default pager for viewing files | `less`, `more`, `bat` | Yes |
| `BROWSER` | Default web browser | `google-chrome`, `firefox` | Yes |
| `TERM` | Terminal type | `xterm-256color` | Yes |
| `LANG` | System language and locale | `en_US.UTF-8` | Yes |
| `LC_ALL` | Override for all locale settings | `en_US.UTF-8` | Yes |

### Path and Directory Variables

| Variable | Purpose | Example Value | Required Export |
|----------|---------|---------------|----------------|
| `HOME` | User home directory | `/home/username` | Yes |
| `PWD` | Current working directory | `/current/path` | Yes |
| `OLDPWD` | Previous working directory | `/previous/path` | Yes |
| `TMPDIR` | Temporary directory | `/tmp` | Yes |
| `XDG_CONFIG_HOME` | User configuration directory | `$HOME/.config` | Yes |
| `XDG_DATA_HOME` | User data directory | `$HOME/.local/share` | Yes |
| `XDG_CACHE_HOME` | User cache directory | `$HOME/.cache` | Yes |

### Language-Specific Variables

#### Go Development
| Variable | Purpose | Example Value | Required Export |
|----------|---------|---------------|----------------|
| `GOPATH` | Go workspace directory | `$HOME/go` | Yes |
| `GOROOT` | Go installation directory | `/usr/local/go` | Yes |
| `GOPROXY` | Go module proxy | `https://proxy.golang.org` | Yes |
| `GOSUMDB` | Go checksum database | `sum.golang.org` | Yes |
| `GOPRIVATE` | Private module patterns | `github.com/company/*` | Yes |
| `GONOPROXY` | Modules to fetch directly | `github.com/company/*` | Yes |
| `GONOSUMDB` | Modules to skip checksum | `github.com/company/*` | Yes |
| `GOOS` | Target operating system | `linux`, `darwin`, `windows` | No |
| `GOARCH` | Target architecture | `amd64`, `arm64` | No |
| `CGO_ENABLED` | Enable/disable CGO | `0`, `1` | No |

#### Python Development
| Variable | Purpose | Example Value | Required Export |
|----------|---------|---------------|----------------|
| `PYTHONPATH` | Python module search path | `/path/to/modules` | Yes |
| `PYTHON_VERSION` | Python version | `3.11` | Yes |
| `VIRTUAL_ENV` | Active virtual environment | `/path/to/venv` | Yes |
| `PIP_INDEX_URL` | PyPI index URL | `https://pypi.org/simple/` | Yes |
| `PYTHONDONTWRITEBYTECODE` | Disable .pyc files | `1` | No |
| `PYTHONUNBUFFERED` | Unbuffered output | `1` | No |

#### Node.js Development
| Variable | Purpose | Example Value | Required Export |
|----------|---------|---------------|----------------|
| `NODE_ENV` | Node environment | `development`, `production` | Yes |
| `NPM_CONFIG_PREFIX` | npm global prefix | `$HOME/.npm-global` | Yes |
| `NODE_PATH` | Node module search path | `/path/to/node_modules` | Yes |
| `NVM_DIR` | Node Version Manager directory | `$HOME/.nvm` | Yes |

#### Rust Development
| Variable | Purpose | Example Value | Required Export |
|----------|---------|---------------|----------------|
| `CARGO_HOME` | Cargo home directory | `$HOME/.cargo` | Yes |
| `RUSTUP_HOME` | Rustup home directory | `$HOME/.rustup` | Yes |
| `RUST_BACKTRACE` | Enable Rust backtraces | `1`, `full` | No |

### Docker and Containerization

| Variable | Purpose | Example Value | Required Export |
|----------|---------|---------------|----------------|
| `DOCKER_HOST` | Docker daemon host | `unix:///var/run/docker.sock` | Yes |
| `DOCKER_CONFIG` | Docker client config directory | `$HOME/.docker` | Yes |
| `COMPOSE_FILE` | Docker Compose file | `docker-compose.yml` | Yes |
| `COMPOSE_PROJECT_NAME` | Docker Compose project name | `myproject` | Yes |

### Cloud Platform Variables

#### AWS
| Variable | Purpose | Example Value | Required Export |
|----------|---------|---------------|----------------|
| `AWS_PROFILE` | AWS profile name | `default`, `prod` | Yes |
| `AWS_REGION` | AWS region | `us-west-2` | Yes |
| `AWS_CONFIG_FILE` | AWS config file | `$HOME/.aws/config` | Yes |
| `AWS_SHARED_CREDENTIALS_FILE` | AWS credentials file | `$HOME/.aws/credentials` | Yes |

#### Google Cloud
| Variable | Purpose | Example Value | Required Export |
|----------|---------|---------------|----------------|
| `GOOGLE_APPLICATION_CREDENTIALS` | Service account key file | `/path/to/key.json` | Yes |
| `GCLOUD_PROJECT` | Default GCP project | `my-project-id` | Yes |

#### Azure
| Variable | Purpose | Example Value | Required Export |
|----------|---------|---------------|----------------|
| `AZURE_CONFIG_DIR` | Azure CLI config directory | `$HOME/.azure` | Yes |
| `AZURE_SUBSCRIPTION_ID` | Default subscription ID | `uuid` | Yes |

### Security and Authentication

| Variable | Purpose | Example Value | Required Export |
|----------|---------|---------------|----------------|
| `SSH_AUTH_SOCK` | SSH agent socket | `/tmp/ssh-agent.sock` | Yes |
| `GPG_TTY` | GPG TTY for signing | `$(tty)` | Yes |
| `GNUPGHOME` | GnuPG home directory | `$HOME/.gnupg` | Yes |

### Development Workflow

| Variable | Purpose | Example Value | Required Export |
|----------|---------|---------------|----------------|
| `CI` | Continuous Integration flag | `true`, `false` | Yes |
| `BUILD_NUMBER` | Build number | `123` | Yes |
| `GIT_AUTHOR_NAME` | Git author name | `John Doe` | Yes |
| `GIT_AUTHOR_EMAIL` | Git author email | `john@example.com` | Yes |
| `GIT_COMMITTER_NAME` | Git committer name | `John Doe` | Yes |
| `GIT_COMMITTER_EMAIL` | Git committer email | `john@example.com` | Yes |

## Variable Schema

Each environment variable in a module should follow this schema:

```json
{
  "name": "VARIABLE_NAME",
  "value": "variable_value",
  "export": true,
  "description": "What this variable does",
  "required": false,
  "sensitive": false,
  "platform_specific": {
    "windows": "windows_specific_value",
    "darwin": "macos_specific_value",
    "linux": "linux_specific_value"
  }
}
```

### Schema Properties

- **name** (required): The environment variable name in UPPER_CASE
- **value** (required): The default value for the variable
- **export** (optional, default: true): Whether to export the variable to child processes
- **description** (optional): Human-readable description of the variable's purpose
- **required** (optional, default: false): Whether this variable is required for the module to function
- **sensitive** (optional, default: false): Whether this variable contains sensitive information
- **platform_specific** (optional): Platform-specific values that override the default value

## Best Practices

1. **Use descriptive names**: Variable names should clearly indicate their purpose
2. **Provide defaults**: Always provide sensible default values when possible
3. **Document everything**: Include descriptions for all non-obvious variables
4. **Consider security**: Mark sensitive variables and avoid hardcoding secrets
5. **Platform compatibility**: Test variables across all supported platforms
6. **Export appropriately**: Only export variables that need to be available to child processes
7. **Use standard locations**: Follow XDG Base Directory specification where applicable
8. **Version awareness**: Consider how variables might change between versions

## Validation Rules

1. Variable names must be in UPPER_CASE with underscores
2. Variable names must not start with a number
3. Variable names should not conflict with system variables
4. Values should not contain unescaped special characters
5. Paths should use forward slashes and be portable across platforms
6. Sensitive variables should not have default values in the registry 
