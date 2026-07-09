Thin Client profile
===================

The thin-client profile installs a small set of host-side tools for connecting to a remote devbox:
- Homebrew (macOS/Linux)
- WezTerm
- VS Code
- chezmoi
- git, gh, ssh

It purposefully omits heavy runtimes and services like Docker, .NET SDK, local Kubernetes, and databases.

Usage:
- On macOS: `./bootstrap.sh --profile thin-client` (routes to macos/install-thin-client.sh)
- On Linux: `./linux/install-thin-client.sh` if provided
