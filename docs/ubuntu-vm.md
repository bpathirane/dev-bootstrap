Ubuntu VM profile
=================

This profile sets up a headless Ubuntu VM as a developer workstation. It installs core CLI tools, language runtimes, and dev tooling. It intentionally skips WSL-only helpers like `wslu` and Windows clipboard bridges.

Recommended order:
1. Create a new VM and SSH into it
2. Run `./bootstrap.sh --profile vm` or `./linux/install-vm.sh`
3. Run `./linux/validate-vm.sh` to verify
4. Optionally run `./linux/install-dotfiles.sh` and `./linux/install-identity.sh`

Notes:
- For UTM/ARM64, ensure the correct architecture is selected. Some packages may need manual builds.
- Corporate CA: use `./linux/install-ca-cert.sh path/to/cert.crt` to add enterprise certificates.
