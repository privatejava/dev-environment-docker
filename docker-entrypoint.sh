#!/bin/bash
set -e

# Default behavior: start SSH daemon (keeps container alive)
# To run interactive bash instead: docker run -it ... dev-environment:latest bash
# To add SSH public key: docker run -e SSH_PUBLIC_KEY="$(cat ~/.ssh/id_rsa.pub)" ...

USER="${USERNAME:-devuser}"
SSH_DIR="/home/${USER}/.ssh"
AUTHORIZED_KEYS="${SSH_DIR}/authorized_keys"

# Setup SSH public key if provided via environment variable
if [ -n "$SSH_PUBLIC_KEY" ]; then
    echo "Setting up SSH public key for ${USER}..."
    mkdir -p "${SSH_DIR}"
    chmod 700 "${SSH_DIR}"
    echo "$SSH_PUBLIC_KEY" >> "${AUTHORIZED_KEYS}"
    chmod 600 "${AUTHORIZED_KEYS}"
    chown -R ${USER}:${USER} "${SSH_DIR}"
    echo "SSH public key added successfully!"
fi

# Check if explicitly requesting bash/sh, otherwise start SSH daemon
# Only start bash if the first argument is explicitly "bash" or "sh"
if [ "$1" = "bash" ] || [ "$1" = "sh" ]; then
    # Interactive bash mode
    echo "Starting interactive bash session as ${USER}..."
    cd /home/${USER}/workspace 2>/dev/null || \
    cd /home/${USER}/projects 2>/dev/null || \
    cd /home/${USER}
    exec su - ${USER} -c "exec /bin/bash"
fi

# Default: Start SSH daemon (keeps container alive)
# Ignore any other arguments (like "sshd" from CMD) and just start the daemon
echo "Starting SSH daemon..."
# Create privilege separation directory if it doesn't exist
mkdir -p /run/sshd
# Start SSH daemon in foreground (keeps container alive)
exec /usr/sbin/sshd -D

