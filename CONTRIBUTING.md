# Contributing to Federated Commons

## Development Setup

1. Clone the repository
2. Copy example configuration files:
   ```bash
   cp config/project.yml.example config/project.yml
   cp config/secrets.yml.example config/secrets.yml
   cp ansible/inventory.ini.example ansible/inventory.ini
   ```
3. Configure your Scaleway credentials (see `docs/00-prerequisites.md`)

## Code Style

- Terraform: Use `terraform fmt` before committing
- Ansible: Follow Ansible best practices; use `ansible-lint` where applicable
- YAML: 2-space indentation, no trailing whitespace

## Pull Requests

1. Fork the repository
2. Create a feature branch from `master`
3. Make your changes
4. Test on a staging environment if possible
5. Submit a PR with a clear description of changes

## Reporting Issues

Open an issue with:
- Description of the problem
- Steps to reproduce
- Expected vs actual behavior
- Environment details (Terraform/Ansible versions, cloud provider)

## Local Override Pattern

This codebase uses a local override pattern for customization:
- `*_local.tf` files are gitignored and override defaults
- `*.example` files document the pattern for each module
- Never commit secrets or org-specific configuration

## License

Contributions are licensed under the project's AGPL-3.0 license.
