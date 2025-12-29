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
    locales \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    # Configure locale to fix locale warnings (C.UTF-8 is already available, just configure it)
    echo "LANG=C.UTF-8" > /etc/default/locale && \
    echo "LC_ALL=C.UTF-8" >> /etc/default/locale && \
    # Create non-root user (Security Best Practice: Do not use root for SSH)
    useradd -ms /bin/bash ${USERNAME} && \
    # Ensure bash is the default shell (explicitly set)
    chsh -s /bin/bash ${USERNAME} && \
    # Add devuser to sudoers (passwordless for convenience in dev environment)
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    # Create SSH directory and set permissions
    mkdir -p /home/${USERNAME}/.ssh && \
    chmod 700 /home/${USERNAME}/.ssh && \
    chown -R ${USERNAME}:${USERNAME} /home/${USERNAME} && \
    # Configure SSH: disable root login and password authentication
    sed -i 's/#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config && \
    sed -i 's/PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config && \
    # Ensure SSH uses the user's default shell (bash)
    sed -i 's/#ForceCommand.*/ForceCommand /' /etc/ssh/sshd_config && \
    echo "AllowUsers ${USERNAME}" >> /etc/ssh/sshd_config

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
    # Note: nvm automatically manages PATH when sourced, we just need to source it
    # For .bashrc (interactive shells)
    echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.bashrc && \
    echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ~/.bashrc && \
    echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> ~/.bashrc && \
    echo 'nvm use default >/dev/null 2>&1 || true' >> ~/.bashrc && \
    # For .profile (login shells - SSH uses this for sh/bash)
    echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.profile && \
    echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ~/.profile && \
    echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> ~/.profile && \
    echo 'nvm use default >/dev/null 2>&1 || true' >> ~/.profile && \
    # For .bash_profile (login bash shells - SSH uses this)
    echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.bash_profile && \
    echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ~/.bash_profile && \
    echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> ~/.bash_profile && \
    echo 'nvm use default >/dev/null 2>&1 || true' >> ~/.bash_profile && \
    # Create common development directories
    mkdir -p ~/projects ~/workspace

# --- Install and Configure Claude Code CLI (separate RUN for easy updates) ---
# Note: Update this section independently when Claude Code CLI needs updating
# This RUN command can be modified/rebuilt separately for Claude Code CLI updates
RUN export NVM_DIR="$HOME/.nvm" && \
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && \
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" && \
    # Remove any conflicting npm config (nvm manages this)
    rm -f ~/.npmrc && \
    # Try npm package @anthropic-ai/claude-code first (most common)
    (npm install -g @anthropic-ai/claude-code 2>/dev/null && \
     echo "✓ Claude Code CLI installed via npm (@anthropic-ai/claude-code)" && \
     CLAUDE_INSTALLED=true) || \
    # Alternative: Try @anthropic/claude-code
    (npm install -g @anthropic/claude-code 2>/dev/null && \
     echo "✓ Claude Code CLI installed via npm (@anthropic/claude-code)" && \
     CLAUDE_INSTALLED=true) || \
    # Fallback: Try official install script
    (curl -fsSL https://claude.ai/install.sh | sh 2>/dev/null && \
     echo "✓ Claude Code CLI installed via official script" && \
     CLAUDE_INSTALLED=true) || \
    # Last resort: Try GitHub release
    (curl -fsSL https://github.com/anthropics/claude-code/releases/latest/download/install.sh | sh 2>/dev/null && \
     echo "✓ Claude Code CLI installed via GitHub release" && \
     CLAUDE_INSTALLED=true) || \
    (echo "⚠ Warning: Claude Code CLI installation failed" && \
     echo "  You may need to install manually after container starts:" && \
     echo "  npm install -g @anthropic-ai/claude-code" && \
     CLAUDE_INSTALLED=false) && \
    # Add common Claude Code CLI paths to PATH (for all shell types)
    echo 'export PATH="$HOME/.claude/bin:$HOME/.local/bin/claude:$PATH"' >> ~/.bashrc && \
    echo 'export PATH="$HOME/.claude/bin:$HOME/.local/bin/claude:$PATH"' >> ~/.profile && \
    echo 'export PATH="$HOME/.claude/bin:$HOME/.local/bin/claude:$PATH"' >> ~/.bash_profile && \
    mkdir -p ~/.config/claude-code && \
    # Add Claude Code to welcome banner info (if installed)
    if [ "$CLAUDE_INSTALLED" = "true" ]; then \
        echo 'export CLAUDE_CODE_AVAILABLE=true' >> ~/.bashrc; \
        echo "✓ Claude Code CLI configured"; \
    fi

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
    # Add Python user bin to PATH (for all shell types)
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc && \
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.profile && \
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bash_profile

# --- Configure Git (with sensible defaults) ---
RUN git config --global init.defaultBranch main && \
    git config --global pull.rebase false && \
    git config --global core.editor vim && \
    git config --global color.ui auto

# --- Create useful aliases and shell enhancements ---
RUN echo '' >> ~/.bashrc && \
    echo '# Welcome banner' >> ~/.bashrc && \
    echo 'if [ -n "$SSH_CONNECTION" ] || [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then' >> ~/.bashrc && \
    echo '    echo ""' >> ~/.bashrc && \
    echo '    echo "╔════════════════════════════════════════════════════════════╗"' >> ~/.bashrc && \
    echo '    echo "║                                                            ║"' >> ~/.bashrc && \
    echo '    echo "║     ██████╗ ███████╗██╗   ██╗    ███████╗███╗   ██╗██╗   ██╗"' >> ~/.bashrc && \
    echo '    echo "║     ██╔══██╗██╔════╝██║   ██║    ██╔════╝████╗  ██║██║   ██║"' >> ~/.bashrc && \
    echo '    echo "║     ██║  ██║█████╗  ██║   ██║    █████╗  ██╔██╗ ██║██║   ██║"' >> ~/.bashrc && \
    echo '    echo "║     ██║  ██║██╔══╝  ╚██╗ ██╔╝    ██╔══╝  ██║╚██╗██║██║   ██║"' >> ~/.bashrc && \
    echo '    echo "║     ██████╔╝███████╗ ╚████╔╝     ███████╗██║ ╚████║╚██████╔╝"' >> ~/.bashrc && \
    echo '    echo "║     ╚═════╝ ╚══════╝  ╚═══╝      ╚══════╝╚═╝  ╚═══╝ ╚═════╝"' >> ~/.bashrc && \
    echo '    echo "║                                                            ║"' >> ~/.bashrc && \
    echo '    echo "║              Development Environment Container             ║"' >> ~/.bashrc && \
    echo '    echo "║                                                            ║"' >> ~/.bashrc && \
    echo '    echo "╠════════════════════════════════════════════════════════════╣"' >> ~/.bashrc && \
    echo '    echo "║  🚀 Ready for Development                                  ║"' >> ~/.bashrc && \
    echo '    echo "║  📦 Node.js 18 (via nvm) | Python 3.11                     ║"' >> ~/.bashrc && \
    echo '    echo "║  🛠️  All tools pre-installed and configured                ║"' >> ~/.bashrc && \
    echo '    echo "║  💻 Claude Code CLI available (type: claude --help)        ║"' >> ~/.bashrc && \
    echo '    echo "║  📁 Workspace: ~/workspace or ~/projects                   ║"' >> ~/.bashrc && \
    echo '    echo "╚════════════════════════════════════════════════════════════╝"' >> ~/.bashrc && \
    echo '    echo ""' >> ~/.bashrc && \
    echo 'fi' >> ~/.bashrc && \
    echo '' >> ~/.bashrc && \
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
    echo 'cd ~/workspace 2>/dev/null || cd ~/projects 2>/dev/null || true' >> ~/.bashrc && \
    # Ensure .bashrc is sourced for login shells (SSH sessions)
    # .bash_profile sources .bashrc for bash login shells
    echo 'if [ -f ~/.bashrc ]; then' >> ~/.bash_profile && \
    echo '    . ~/.bashrc' >> ~/.bash_profile && \
    echo 'fi' >> ~/.bash_profile && \
    # .profile sources .bashrc for bash shells (SSH uses this)
    echo 'if [ -n "$BASH_VERSION" ]; then' >> ~/.profile && \
    echo '    if [ -f ~/.bashrc ]; then' >> ~/.profile && \
    echo '        . ~/.bashrc' >> ~/.profile && \
    echo '    fi' >> ~/.profile && \
    echo 'fi' >> ~/.profile && \
    # Also add essential environment variables directly to .profile for non-bash shells
    echo 'export LANG=C.UTF-8' >> ~/.profile && \
    echo 'export LC_ALL=C.UTF-8' >> ~/.profile && \
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.profile

# --- Install Playwright (separate RUN for easy updates and layer caching) ---
# Install both Node.js and Python versions of Playwright
RUN export NVM_DIR="$HOME/.nvm" && \
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && \
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" && \
    # Install Node.js version
    npm install -g playwright && \
    # Install Python version
    python3 -m pip install --user playwright && \
    # Install browser binaries (shared between Node.js and Python)
    # Use sudo -E to preserve environment variables (PATH) so npx is found
    sudo -E env "PATH=$PATH" npx playwright install --with-deps chromium firefox webkit

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