# Use the official Python 3.11 slim image as the base
FROM python:3.11-slim-bullseye

# Set environment variables for the SSH setup
ENV SSH_PORT=22 \
    USERNAME=devuser \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# --- Install comprehensive development tools and configure SSH ---
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    # SSH and networking
    openssh-server \
    openssh-client \
    net-tools \
    iputils-ping \
    dnsutils \
    # Version control
    git \
    git-lfs \
    # Build tools (for native Node.js modules and Python packages)
    build-essential \
    gcc \
    g++ \
    make \
    cmake \
    pkg-config \
    # Python development
    python3-dev \
    python3-venv \
    python3-pip \
    # System utilities
    curl \
    wget \
    procps \
    htop \
    tree \
    jq \
    less \
    nano \
    vim \
    # Archive tools
    zip \
    unzip \
    tar \
    gzip \
    # Network and debugging
    netcat-openbsd \
    tcpdump \
    strace \
    # Terminal multiplexer
    tmux \
    screen \
    # SSL/TLS certificates
    ca-certificates \
    gnupg \
    lsb-release \
    # Additional utilities
    sudo \
    bash-completion \
    man-db \
    manpages \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    # Create non-root user (Security Best Practice: Do not use root for SSH)
    useradd -ms /bin/bash ${USERNAME} && \
    # Add devuser to sudoers (passwordless for convenience in dev environment)
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    # Create SSH directory and set permissions
    mkdir -p /home/${USERNAME}/.ssh && \
    chmod 700 /home/${USERNAME}/.ssh && \
    chown -R ${USERNAME}:${USERNAME} /home/${USERNAME} && \
    # Configure SSH: disable root login and password authentication
    sed -i 's/#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config && \
    sed -i 's/PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config

# --- Install nvm, Node.js 18, and Node.js development tools ---
USER ${USERNAME}
WORKDIR /home/${USERNAME}

# Install nvm and Node.js 18 with development tools
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash && \
    export NVM_DIR="$HOME/.nvm" && \
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && \
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" && \
    nvm install 18 && \
    nvm alias default 18 && \
    nvm use default && \
    # Install global Node.js development tools
    npm install -g \
    yarn \
    pnpm \
    nodemon \
    pm2 \
    typescript \
    ts-node \
    eslint \
    prettier \
    jest \
    @types/node \
    && \
    # Get the installed Node.js version path
    NODE_PATH=$(nvm which default) && \
    NODE_DIR=$(dirname "$NODE_PATH") && \
    # Add nvm to PATH for interactive and non-interactive shells
    echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.bashrc && \
    echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ~/.bashrc && \
    echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> ~/.bashrc && \
    echo "export PATH=\"$NODE_DIR:\$PATH\"" >> ~/.bashrc && \
    # Also add to .profile for non-interactive shells
    echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.profile && \
    echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ~/.profile && \
    echo "export PATH=\"$NODE_DIR:\$PATH\"" >> ~/.profile && \
    # Create common development directories
    mkdir -p ~/projects ~/workspace

# --- Install Cursor CLI (separate RUN for easy updates) ---
# Note: Update this section independently when Cursor CLI needs updating
# This RUN command can be modified/rebuilt separately for Cursor CLI updates
RUN export NVM_DIR="$HOME/.nvm" && \
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && \
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" && \
    # Try npm package first (recommended method)
    if npm install -g @cursor/cli 2>/dev/null; then \
        echo "Cursor CLI installed via npm"; \
    # Fallback to official install script
    elif curl -fsSL https://cursor.sh/install.sh | sh 2>/dev/null; then \
        echo "Cursor CLI installed via install script"; \
    # Alternative installation method
    elif curl -fsSL https://update.cursor.sh/install.sh | sh 2>/dev/null; then \
        echo "Cursor CLI installed via update script"; \
    else \
        echo "Warning: Cursor CLI installation failed - you may need to install manually"; \
    fi && \
    # Add common Cursor CLI paths to PATH
    echo 'export PATH="$HOME/.cursor/bin:$PATH"' >> ~/.bashrc && \
    echo 'export PATH="$HOME/.local/bin/cursor:$PATH"' >> ~/.bashrc && \
    echo 'export PATH="$HOME/.cursor/bin:$PATH"' >> ~/.profile && \
    echo 'export PATH="$HOME/.local/bin/cursor:$PATH"' >> ~/.profile && \
    # Verify installation (optional check)
    (command -v cursor >/dev/null 2>&1 || echo "Note: cursor command may need shell restart to be available")

# --- Install Python development tools ---
RUN python3 -m pip install --upgrade pip setuptools wheel && \
    python3 -m pip install --user \
    virtualenv \
    pipenv \
    poetry \
    ipython \
    ipdb \
    pytest \
    pytest-cov \
    black \
    flake8 \
    pylint \
    mypy \
    requests \
    && \
    # Add Python user bin to PATH
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc && \
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.profile

# --- Configure Git (with sensible defaults) ---
RUN git config --global init.defaultBranch main && \
    git config --global pull.rebase false && \
    git config --global core.editor vim && \
    git config --global color.ui auto

# --- Create useful aliases and shell enhancements ---
RUN echo '' >> ~/.bashrc && \
    echo '# Locale settings' >> ~/.bashrc && \
    echo 'export LANG=C.UTF-8' >> ~/.bashrc && \
    echo 'export LC_ALL=C.UTF-8' >> ~/.bashrc && \
    echo '' >> ~/.bashrc && \
    echo '# Development aliases' >> ~/.bashrc && \
    echo 'alias ll="ls -alF"' >> ~/.bashrc && \
    echo 'alias la="ls -A"' >> ~/.bashrc && \
    echo 'alias l="ls -CF"' >> ~/.bashrc && \
    echo 'alias ..="cd .."' >> ~/.bashrc && \
    echo 'alias ...="cd ../.."' >> ~/.bashrc && \
    echo 'alias grep="grep --color=auto"' >> ~/.bashrc && \
    echo 'alias fgrep="fgrep --color=auto"' >> ~/.bashrc && \
    echo 'alias egrep="egrep --color=auto"' >> ~/.bashrc && \
    echo 'alias python="python3"' >> ~/.bashrc && \
    echo 'alias pip="pip3"' >> ~/.bashrc && \
    echo 'alias venv="python3 -m venv"' >> ~/.bashrc && \
    echo 'alias activate="source venv/bin/activate"' >> ~/.bashrc && \
    echo '' >> ~/.bashrc && \
    echo '# Enable bash completion' >> ~/.bashrc && \
    echo 'if ! shopt -oq posix; then' >> ~/.bashrc && \
    echo '  if [ -f /usr/share/bash-completion/bash_completion ]; then' >> ~/.bashrc && \
    echo '    . /usr/share/bash-completion/bash_completion' >> ~/.bashrc && \
    echo '  elif [ -f /etc/bash_completion ]; then' >> ~/.bashrc && \
    echo '    . /etc/bash_completion' >> ~/.bashrc && \
    echo '  fi' >> ~/.bashrc && \
    echo 'fi' >> ~/.bashrc && \
    echo '' >> ~/.bashrc && \
    echo '# Set default directory' >> ~/.bashrc && \
    echo 'cd ~/workspace 2>/dev/null || cd ~/projects 2>/dev/null || true' >> ~/.bashrc

# Switch back to root for SSH daemon and entrypoint setup
USER root

# Copy and setup entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Expose the SSH port
EXPOSE ${SSH_PORT}

# --- Runtime Setup ---
# Default behavior: SSH daemon (keeps container alive)
# To run interactive bash: docker run -it ... dev-environment:latest bash
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["sshd"]