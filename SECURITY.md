# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability, please report it privately:

1. **Do not** open a public issue
2. Email security concerns to the maintainers (see repository contacts)
3. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

We will acknowledge receipt within 48 hours and provide updates on remediation.

## Security Design

### Secrets Management
- All secrets stored in Scaleway Secret Manager
- No hardcoded credentials in version control
- `.gitignore` excludes local configuration files

### Network Security
- UFW firewall on all hosts
- Private network (VPC) for inter-service communication
- Public access only via Traefik reverse proxy with TLS

### Authentication
- Authentik provides SSO/OIDC for all applications
- MFA enforced for administrative access
- Regular credential rotation

### Monitoring
- Wazuh for security event monitoring
- Fail2ban for brute-force protection
- Centralized logging via Loki

## Supported Versions

We maintain security updates for the latest release only.
