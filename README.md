# Mountain Jewels Deploy

Deployment scripts and GitHub Actions workflows for Mountain Jewels infrastructure.

## Overview

This repository contains deployment automation for the Mountain Jewels platform.

## Structure

```
mountainjewels-deploy/
├── .github/
│   └── workflows/    # GitHub Actions deployment workflows
└── scripts/          # Deployment shell scripts
```

## Usage

### Manual Deployment

```bash
./scripts/deploy.sh <environment>
```

### Automated Deployment

Deployments are triggered automatically via GitHub Actions when:
- Push to `main` branch
- Manual workflow dispatch

## Required Secrets

Configure these in your GitHub repository settings:

- `AZURE_CREDENTIALS` - Azure service principal JSON
- `ACR_NAME` - Azure Container Registry name
- `KEYVAULT_NAME` - Azure Key Vault name (optional)

## Related Repositories

- [mountainjewels-autodeploy](https://github.com/colin-coates/mountainjewels-autodeploy) - Reusable workflow templates

## License

Proprietary - Mountain Jewels © 2024
