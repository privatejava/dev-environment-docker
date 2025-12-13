# Dev Environment Docker - Quick Summary

## What This Is
A Docker image that provides a complete development environment for Node.js and Python projects. **Defaults to interactive bash** - just run and start coding!

## Quick Start
```bash
make build && make run
```

## Key Facts
- **Base**: Python 3.11 slim (Debian)
- **Node.js**: 18 via nvm
- **User**: `devuser` (non-root, with sudo)
- **Default Mode**: Interactive bash (not SSH)
- **Workspace**: Auto-navigates to `~/workspace` or `~/projects`

## Common Commands
- `make build` - Build image
- `make run` - Interactive bash (DEFAULT)
- `make run-sshd PORT=2222` - SSH daemon mode
- `make bash-root` - Bash as root

## Project Files
- `Dockerfile` - Image definition
- `docker-entrypoint.sh` - Mode switcher (bash/SSH)
- `Makefile` - Convenient commands
- `.ai-context.md` - Full project context for AI
- `.cursorrules` - Cursor IDE rules

## Important Notes
- Container auto-removes on exit
- All tools pre-installed and configured
- Cursor CLI in separate RUN (easy to update)
- Makefile uses `CONTAINER_USER` (not `USERNAME`)

For detailed information, see `.ai-context.md`

