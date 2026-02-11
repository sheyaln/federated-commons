# Terraform Grafana Dashboards

manages grafana dashboards and datasources with terraform instead of ansible cause the json escaping was a nightmare.

## Architecture

```bash
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Ansible-VPS   │    │  Terraform      │    │    Grafana      │
│                 │    │  Grafana        │    │   Instance      │
│ • Deploy Service│───▶│ • Dashboards    │───▶│ • Dashboards    │
│ • Basic Config  │    │ • Datasources   │    │ • Datasources   │
│ • Environment   │    │ • Folders       │    │ • Folders       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```


## Prerequisites

1. **Grafana Instance**: Running and accessible
   - Deployed via `ansible-vps/playbook-management.yml`
   - Accessible at `https://grafana.example.cc` (or staging)

2. **Terraform**: Version >= 1.0

   ```bash
   # Install on macOS
   brew install terraform
   
   # Or download from terraform.io
   ```

3. **Grafana Admin Credentials**: For API access

## Quick Start

1. **Clone and Setup**

   ```bash
   cd terraform-grafana-dashboards
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Configure Variables**

   ```bash
   # Edit terraform.tfvars with your values
   vim terraform.tfvars
   ```

3. **Initialize and Apply**

   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## Configuration

### Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `grafana_url` | Grafana instance URL | `https://grafana.example.cc` | No |
| `grafana_auth` | Admin credentials (`admin:password`) | - | **Yes** |
| `prometheus_url` | Prometheus URL | `http://prometheus:9090` | No |
| `loki_url` | Loki URL | `http://loki:3100` | No |
| `environment` | Environment name | `production` | No |

### Example terraform.tfvars

```hcl
grafana_auth = "admin:your_secure_password"
grafana_url  = "https://grafana.example.cc"

# For staging
# grafana_url = "https://grafana.example.com"

# Custom datasource URLs if needed
# prometheus_url = "http://custom-prometheus:9090"
# loki_url = "http://custom-loki:3100"
```

## Dashboard Structure

### Folders

- **Infrastructure**: System and infrastructure metrics
- **Applications**: Application-specific dashboards
- **Security**: Security monitoring and alerting

### Current Dashboards

- **Node Exporter Full**: CPU, Memory, Disk, Network, Load
- **Docker Container Monitoring**: Container stats and resource usage

## Adding New Dashboards

1. **Create Dashboard Resource**

   ```hcl
   resource "grafana_dashboard" "my_dashboard" {
     folder      = grafana_folder.applications.id
     config_json = jsonencode({
       dashboard = {
         title = "My Application Dashboard"
         # ... dashboard config
       }
     })
   }
   ```

2. **Export from Grafana UI**
   - Create dashboard in Grafana UI
   - Export JSON
   - Convert to Terraform HCL format

3. **Use Dashboard JSON Files**

   ```hcl
   resource "grafana_dashboard" "from_file" {
     folder      = grafana_folder.applications.id
     config_json = file("${path.module}/dashboards/my-dashboard.json")
   }
   ```

## Environment Management

### Production

```bash
terraform workspace select production
# or
TF_VAR_grafana_url="https://grafana.example.cc" terraform apply
```

### Staging

```bash
terraform workspace select staging
# or  
TF_VAR_grafana_url="https://grafana.example.com" terraform apply
```

## Best Practices

1. **Version Control**: Always commit changes before applying
2. **Plan First**: Run `terraform plan` to review changes
3. **Small Changes**: Make incremental dashboard changes
4. **Testing**: Test dashboards in staging first
5. **Backup**: Export dashboards before major changes

## Troubleshooting

### Authentication Issues

```bash
# Test API access
curl -u admin:password https://grafana.example.cc/api/health
```

### Provider Issues

```bash
# Re-initialize provider
terraform init -upgrade
```

### Dashboard Conflicts

```bash
# Import existing dashboard
terraform import grafana_dashboard.my_dashboard <dashboard-uid>
```

## Integration with Ansible

This repository complements the `ansible-vps` repository:

1. **Ansible**: Deploys Grafana service and basic configuration
2. **Terraform**: Manages dashboards, datasources, and advanced config

### Deployment Workflow

```bash
# 1. Deploy Grafana service
cd ansible-vps
ansible-playbook playbook-management.yml -i inventory.ini --tags grafana

# 2. Configure dashboards  
cd ../terraform-grafana-dashboards
terraform apply
```

## Contributing

1. Fork the repository
2. Create feature branch
3. Test changes in staging
4. Submit pull request
5. Apply to production after review

## Security

- **Sensitive Variables**: Use `terraform.tfvars` (gitignored)
- **API Access**: Limit Grafana admin access
- **State Files**: Secure Terraform state storage
- **Credentials**: Rotate Grafana passwords regularly
