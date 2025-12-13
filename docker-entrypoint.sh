#!/bin/bash
set -e

# Default behavior: start interactive bash as devuser
# To run SSH daemon instead, use: docker run ... dev-environment:latest sshd

if [ "$1" = "sshd" ] || [ "$1" = "ssh" ]; then
    # Start SSH daemon
    echo "Starting SSH daemon..."
    exec /usr/sbin/sshd -D
elif [ "$#" -eq 0 ] || [ "$1" = "bash" ] || [ "$1" = "sh" ]; then
    # Default: start interactive bash as devuser
    USER="${USERNAME:-devuser}"
    echo "Starting interactive bash session as ${USER}..."
    cd /home/${USER}/workspace 2>/dev/null || \
    cd /home/${USER}/projects 2>/dev/null || \
    cd /home/${USER}
    exec su - ${USER} -c "exec /bin/bash"
else
    # Execute any other command passed
    exec "$@"
fi

