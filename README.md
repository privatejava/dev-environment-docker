# Dev Environment Docker Image

A systematic Docker image build system for a development environment with SSH access.

## Features

- Python 3.11 slim base image
- SSH server configured for secure access
- Essential development tools (curl, wget, vim, procps)
- Non-root user for security
- Optimized Dockerfile with minimal layers

## Quick Start

### Using the Build Script

```bash
# Make the script executable
chmod +x build.sh

# Build with defaults
./build.sh

# Build with custom tag
./build.sh -t v1.0.0

# Build without cache
./build.sh --no-cache

# Build for specific platform
./build.sh --platform linux/amd64

# Show all options
./build.sh --help
```

### Using Make

```bash
# Build the image
make build

# Build without cache
make build-no-cache

# Build with verbose output
make build-verbose

# Run the container with SSH daemon (DEFAULT - keeps container alive)
make run PORT=2222

# With SSH public key (so you can login immediately)
make run PORT=2222 SSH_PUBLIC_KEY="$(cat ~/.ssh/id_rsa.pub)"

# Run interactively with bash (container exits when you exit)
make bash

# View logs (for SSH mode)
make logs

# Get a shell in the running container (requires container to be running in SSH mode)
make shell

# Start interactive bash session (same as 'make run')
make bash

# Start interactive bash session as root
make bash-root

# Stop the container
make stop

# Test the image
make test

# Clean up
make clean

# Show all available commands
make help
```

### Using Docker Directly

```bash
# Basic build
docker build -t dev-environment:latest .

# Build with custom tag
docker build -t dev-environment:v1.0.0 .

# Run container interactively with bash (DEFAULT - recommended for development)
docker run -it --rm --name dev-env-interactive dev-environment:latest

# Run container in background with SSH daemon
docker run -d -p 2222:22 --name dev-env dev-environment:latest sshd

# Access via SSH (after setting up SSH keys and running in SSH mode)
ssh -p 2222 devuser@localhost
```

## Build Options

### Environment Variables

You can override defaults using environment variables:

```bash
export IMAGE_NAME=my-dev-env
export IMAGE_TAG=v1.0.0
export DOCKERFILE=Dockerfile
export BUILD_CONTEXT=.
```

### Build Script Options

- `-n, --name NAME`: Image name (default: dev-environment)
- `-t, --tag TAG`: Image tag (default: latest)
- `-f, --file FILE`: Dockerfile path (default: Dockerfile)
- `-c, --context PATH`: Build context path (default: .)
- `--no-cache`: Build without using cache
- `--pull`: Always pull base image before building
- `--platform PLATFORM`: Target platform (e.g., linux/amd64, linux/arm64)
- `-v, --verbose`: Verbose output
- `-h, --help`: Show help message

### Makefile Targets

- `build`: Build the Docker image
- `build-no-cache`: Build without cache
- `build-pull`: Build with --pull flag
- `build-verbose`: Build with verbose output
- `tag`: Tag the image (usage: `make tag NEW_TAG=v1.0.0`)
- `run`: Run the container with SSH daemon (DEFAULT - keeps container alive, usage: `make run PORT=2222 SSH_PUBLIC_KEY="$(cat ~/.ssh/id_rsa.pub)"`)
- `bash`: Run the container interactively with bash (container exits when you exit)
- `bash-root`: Run the container interactively as root
- `stop`: Stop the running container
- `logs`: Show container logs
- `shell`: Get a shell in the running container (requires container to be running)
- `inspect`: Inspect the Docker image
- `size`: Show image size
- `history`: Show image build history
- `clean`: Remove the Docker image
- `clean-all`: Remove image and stop/remove container
- `test`: Run basic tests on the image

## Default Behavior: SSH Daemon (Container Stays Alive)

**The container defaults to SSH daemon mode** - it starts and stays running so you can SSH into it anytime.

### Quick Start - SSH Daemon (Default)

**Using Make:**
```bash
# Start container with SSH daemon (keeps container alive)
make run PORT=2222

# With SSH public key (so you can login immediately)
make run PORT=2222 SSH_PUBLIC_KEY="$(cat ~/.ssh/id_rsa.pub)"
```

**Using Docker directly:**
```bash
# Start container with SSH daemon (DEFAULT)
docker run -d -p 2222:22 --name dev-env dev-environment:latest

# With SSH public key
docker run -d -p 2222:22 \
  -e SSH_PUBLIC_KEY="$(cat ~/.ssh/id_rsa.pub)" \
  --name dev-env \
  dev-environment:latest

# SSH into the container
ssh -p 2222 devuser@localhost
```

**Key points:**
- **Default behavior**: Container starts SSH daemon and stays alive
- Container runs in background (`-d` flag)
- Pass `SSH_PUBLIC_KEY` env var to enable immediate SSH access
- Container keeps running until you stop it

### Interactive Bash Mode (Optional)

If you want an interactive bash session that exits when you're done:

```bash
# Using Make
make bash

# Using Docker
docker run -it --rm dev-environment:latest bash
```

## SSH Configuration

The image is configured with:
- Non-root user: `devuser`
- SSH port: `22` (exposed, map to host port as needed)
- Root login: Disabled
- Password authentication: Disabled (key-based only)

### Setting Up SSH Access

**Simple way - Pass your public key as environment variable:**

```bash
# Using Make
make run PORT=2222 SSH_PUBLIC_KEY="$(cat ~/.ssh/id_rsa.pub)"

# Using Docker directly
docker run -d -p 2222:22 \
  -e SSH_PUBLIC_KEY="$(cat ~/.ssh/id_rsa.pub)" \
  --name dev-env \
  dev-environment:latest

# Or pass the key directly
docker run -d -p 2222:22 \
  -e SSH_PUBLIC_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAA..." \
  --name dev-env \
  dev-environment:latest

# Then SSH into the container
ssh -p 2222 devuser@localhost
```

### Manual SSH Key Setup (Alternative)

If you prefer to set up SSH keys manually after the container is running:

1. Generate SSH key pair (if you don't have one):
   ```bash
   ssh-keygen -t ed25519 -C "dev-environment"
   ```

2. Copy your public key to the container:
   ```bash
   docker cp ~/.ssh/id_ed25519.pub dev-env:/home/devuser/.ssh/authorized_keys
   docker exec dev-env chown devuser:devuser /home/devuser/.ssh/authorized_keys
   docker exec dev-env chmod 600 /home/devuser/.ssh/authorized_keys
   ```

3. Connect via SSH:
   ```bash
   ssh -p 2222 devuser@localhost
   ```

## Image Optimization

The Dockerfile is optimized for:
- **Minimal layers**: Combined RUN commands to reduce image layers
- **Smaller size**: Using `--no-install-recommends` and cleaning up apt cache
- **Better caching**: Logical grouping of operations for optimal layer caching
- **Security**: Non-root user, disabled password authentication

## Versioning

Recommended versioning strategy:

```bash
# Development builds
./build.sh -t dev

# Release builds
./build.sh -t v1.0.0
./build.sh -t v1.0.0 -n my-dev-environment

# Using Make
make build IMAGE_TAG=v1.0.0
make tag NEW_TAG=v1.0.0
```

## Troubleshooting

### Build fails
- Check Docker is running: `docker ps`
- Verify Dockerfile syntax
- Try building with `--no-cache` flag

### Container won't start
- Check logs: `docker logs dev-env`
- Verify port is not in use: `netstat -tuln | grep 2222`
- Try running with `make run` or `docker run` directly

### SSH connection fails
- Verify container is running: `docker ps`
- Check SSH keys are properly set up
- Verify port mapping: `docker port dev-env`

## License

This project is provided as-is for development purposes.

# dev-environment-docker
