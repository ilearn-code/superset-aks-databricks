# Apache Superset on Azure Kubernetes Service (AKS)# Apache Superset on AKS with Azure Databricks Integration



A production-ready deployment of Apache Superset on Azure Kubernetes Service with Azure Databricks integration, featuring a hybrid CI/CD pipeline using GitHub Actions and Azure DevOps.[![Build Status](https://dev.azure.com/your-org/Flash-Superset/_apis/build/status/Superset-CI?branchName=main)](https://dev.azure.com/your-org/Flash-Superset/_build/latest?definitionId=1&branchName=main)

[![Deployment](https://img.shields.io/badge/deployment-Azure%20DevOps-blue)](https://dev.azure.com/your-org/Flash-Superset/_release)

## 🎯 Overview

This project provides a comprehensive, **production-ready** solution for deploying Apache Superset on Azure Kubernetes Service (AKS) with integration to Azure Databricks. It includes complete infrastructure as code, CI/CD pipelines using **Azure DevOps**, security configurations, and operational excellence practices.

This repository provides a complete solution for deploying Apache Superset with:

## 🌟 Features

- ✅ **Containerized Apache Superset** with Databricks connectors

- ✅ **Azure Kubernetes Service (AKS)** cluster deployment- ✅ **Production-Ready**: High availability, auto-scaling, and disaster recovery

- ✅ **Hybrid CI/CD Pipeline** (GitHub Actions + Azure DevOps)- ✅ **Azure Native**: Fully integrated with Azure services (AKS, ACR, Key Vault, Databricks)

- ✅ **Azure Container Registry** for secure image storage- ✅ **CI/CD with Azure DevOps**: Automated pipelines for build, test, and deployment

- ✅ **Azure Databricks integration** for advanced analytics- ✅ **Security First**: Azure AD OAuth, RBAC, network policies, and secrets management

- ✅ **Production-ready security** configurations- ✅ **Infrastructure as Code**: Terraform modules for reproducible deployments

- ✅ **Comprehensive documentation** and troubleshooting guides- ✅ **Databricks Integration**: Pre-configured ODBC drivers and connectors



## 🚀 Quick Start## 🏗 Architecture



### For New Users```

1. **[Getting Started Guide](docs/quickstart/getting-started.md)** - Essential first stepsAzure Cloud

2. **[Quick Deploy Guide](docs/quickstart/quick-deploy.md)** - Rapid deployment├── Azure Kubernetes Service (AKS)

3. **[Next Steps](docs/quickstart/next-steps.md)** - Post-deployment tasks│   ├── Superset Pods (3+ replicas with auto-scaling)

│   ├── PostgreSQL (metadata store)

### For Production Deployment│   └── Redis (caching layer)

1. **[Complete Setup Reference](docs/reference/complete-setup-reference.md)** - Comprehensive guide├── Azure Container Registry (ACR)

2. **[Security Best Practices](docs/reference/security.md)** - Production security├── Azure Databricks (data source)

3. **[CI/CD Enhancement Guide](docs/cicd/enhancement-guide.md)** - Advanced pipeline features├── Azure Key Vault (secrets management)

└── Azure Active Directory (authentication)

## 📚 Documentation Structure```



### 🚀 [Quick Start](docs/quickstart/)## 📋 Table of Contents

- [Getting Started](docs/quickstart/getting-started.md)

- [Quick Deploy](docs/quickstart/quick-deploy.md)- [Quick Start](#quick-start)

- [Next Steps](docs/quickstart/next-steps.md)- [Prerequisites](#prerequisites)

- [Documentation](#documentation)

### ⚙️ [Setup & Configuration](docs/setup/)- [CI/CD with Azure DevOps](#cicd-with-azure-devops)

- [Initial Setup](docs/setup/initial-setup.md)- [Deployment](#deployment)

- [Azure Configuration](docs/setup/azure-configuration.md)- [Configuration](#configuration)

- [AKS Configuration](docs/setup/aks-configuration.md)- [Troubleshooting](#troubleshooting)

- [Key Vault Setup](docs/setup/key-vault-setup.md)- [Contributing](#contributing)



### 🔄 [CI/CD Pipeline](docs/cicd/)## 🚀 Quick Start

- [CI/CD Overview](docs/cicd/overview.md)

- [GitHub Actions Setup](docs/cicd/github-actions-setup.md)```powershell

- [Azure DevOps Setup](docs/cicd/azure-devops-setup.md)# Clone the repository

- [Enhancement Guide](docs/cicd/enhancement-guide.md)git clone https://dev.azure.com/your-org/Flash-Superset/_git/superset-aks-databricks

- [Hybrid Setup](docs/cicd/hybrid-setup.md)cd superset-aks-databricks



### 🚢 [Deployment](docs/deployment/)# Run quick start script

- [Manual Deployment](docs/deployment/manual-deployment.md).\quick-start.ps1

- [Automated Deployment](docs/deployment/automated-deployment.md)

- [Helm Deployment](docs/deployment/helm-deployment.md)# Or follow manual steps in DEPLOYMENT.md

- [kubectl Deployment](docs/deployment/kubectl-deployment.md)```



### 📖 [Reference](docs/reference/)**Current POC Environment**: [AKS Flash Superset Dev](https://portal.azure.com/#@<YOUR-TENANT>.onmicrosoft.com/resource/subscriptions/<YOUR-SUBSCRIPTION-ID>/resourceGroups/<YOUR-RESOURCE-GROUP>/providers/Microsoft.ContainerService/managedClusters/<YOUR-AKS-CLUSTER>/overview)

- [Complete Setup Reference](docs/reference/complete-setup-reference.md)

- [Architecture Overview](docs/reference/architecture.md)## 📦 Prerequisites

- [Configuration Reference](docs/reference/configuration.md)

- [Security Best Practices](docs/reference/security.md)### Required Tools

- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) >= 2.40

### 🔧 [Troubleshooting](docs/troubleshooting/)- [kubectl](https://kubernetes.io/docs/tasks/tools/) >= 1.25

- [Common Issues](docs/troubleshooting/common-issues.md)- [Helm](https://helm.sh/docs/intro/install/) >= 3.10

- [Pipeline Issues](docs/troubleshooting/pipeline-issues.md)- [Terraform](https://www.terraform.io/downloads) >= 1.3

- [ACR Issues](docs/troubleshooting/acr-issues.md)- [Docker Desktop](https://www.docker.com/products/docker-desktop/) >= 20.10

- [Key Vault Issues](docs/troubleshooting/key-vault-issues.md)

### Azure Resources

## 🏗️ Architecture- Azure subscription with Contributor access

- Azure DevOps organization and project

```mermaid- Sufficient quota for:

graph TB  - 3+ Standard_D4s_v3 VMs (AKS nodes)

    subgraph "CI/CD Pipeline"  - Azure Container Registry (Premium for production)

        GH[GitHub Actions<br/>Build & Test] --> ACR[Azure Container Registry]  - Azure Databricks workspace

        ACR --> ADO[Azure DevOps<br/>Deploy]

    end## 📚 Documentation

    

    subgraph "Azure Infrastructure"- **[DEPLOYMENT.md](DEPLOYMENT.md)** - Complete production deployment guide

        ADO --> AKS[Azure Kubernetes Service]- **[docs/azure-devops-setup.md](docs/azure-devops-setup.md)** - Azure DevOps CI/CD setup

        AKS --> SS[Superset Application]- **[docs/configuration.md](docs/configuration.md)** - Configuration reference

        SS --> ADB[Azure Databricks]- **[docs/troubleshooting.md](docs/troubleshooting.md)** - Common issues and solutions

        SS --> KV[Azure Key Vault]

        SS --> REDIS[Redis Cache]## 🔄 CI/CD with Azure DevOps

    end

    This project uses Azure DevOps for continuous integration and deployment:

    subgraph "External Access"

        USERS[Users] --> LB[Azure LoadBalancer]### Pipelines

        LB --> SS

    end1. **CI Pipeline** (`azure-pipelines/ci-pipeline.yml`)

```   - Linting and validation

   - Unit tests with coverage

## 🎯 Key Features   - Docker image build and push to ACR

   - Security scanning

### Hybrid CI/CD Pipeline   - Artifact publishing

- **GitHub Actions (CI)**: Build, test, security scan, push to ACR

- **Azure DevOps (CD)**: Environment-specific deployments with approvals2. **CD Dev Pipeline** (`azure-pipelines/cd-dev-pipeline.yml`)

- **Automated Initialization**: Database migration, admin user creation, role setup   - Automated deployment to development

   - Infrastructure provisioning with Terraform

### Production-Ready Security   - Application deployment with Helm

- Azure Key Vault integration for secrets management   - Smoke tests

- Network policies and RBAC configuration

- Container image security scanning3. **CD Prod Pipeline** (`azure-pipelines/cd-prod-pipeline.yml`)

- TLS/SSL encryption support   - Manual approvals required

   - Production backup before deployment

### Scalability & High Availability

- Horizontal Pod Autoscaler (HPA) configuration   - Post-deployment validation

- Multi-node AKS cluster setup

- LoadBalancer with external IP access### Pipeline Flow

- Redis caching for performance

```

## 🛠️ Available ScriptsCode Push → CI Pipeline → CD Dev → CD Staging → CD Prod

    ↓           ↓            ↓          ↓           ↓

### Quick Deployment  Build     Test/Scan    Auto-Deploy Manual     Manual

```bash  Image                              Approval   Approval

# Deploy with specific image tag```

./scripts/quick-deploy.sh <image-tag> [namespace]

### Setup Azure DevOps

# Initialize Superset for any environment

./scripts/init-superset.sh <namespace> <admin-user> <admin-password> <email>```powershell

```# Follow the complete guide

Get-Content docs\azure-devops-setup.md

### Environment Files

- `environments/dev/values.yaml` - Development configuration# Or quick setup:

- `environments/staging/values.yaml` - Staging configuration  # 1. Create project in Azure DevOps

- `environments/prod/values.yaml` - Production configuration# 2. Import this repository

# 3. Create service connections

## 🔑 Prerequisites# 4. Configure variable groups

# 5. Create pipelines from YAML files

- Azure CLI installed and configured```

- kubectl configured for AKS access

- Docker (for local builds)## 🏗 Deployment

- Helm 3.x (for Helm deployments)

- Access to Azure subscription with appropriate permissions### Option 1: Quick Start Script (Recommended)



## 🎉 Current Status```bash

./quick-start.sh

| Component | Status | Version |```

|-----------|---------|---------|

| **CI Pipeline** | ✅ Working | GitHub Actions |### Option 2: Manual Deployment

| **CD Pipeline** | ✅ Enhanced | Azure DevOps |

| **AKS Deployment** | ✅ Running | Kubernetes 1.28+ |#### 1. Deploy Infrastructure with Terraform

| **Superset App** | ✅ Accessible | Apache Superset 2.1.0 |

| **Documentation** | ✅ Complete | v1.0 |```bash

cd terraform

**Access URLs**:

- Development: http://<YOUR-DEV-EXTERNAL-IP>:8088terraform init \

- Staging: (Configure in Azure DevOps)  -backend-config="resource_group_name=rg-terraform-state" \

- Production: (Configure in Azure DevOps)  -backend-config="storage_account_name=sttfstateflashsuperset" \

  -backend-config="container_name=tfstate" \

**Default Credentials**: retrieve credentials from Key Vault or your deployment pipeline secret store.  -backend-config="key=superset-prod.tfstate"



## 🤝 Contributingterraform plan -var-file="environments/prod.tfvars" -out=tfplan

terraform apply tfplan

1. Fork the repository```

2. Create a feature branch: `git checkout -b feature/amazing-feature`

3. Commit your changes: `git commit -m 'Add amazing feature'`#### 2. Build and Push Docker Image

4. Push to the branch: `git push origin feature/amazing-feature`

5. Open a Pull Request```bash

az acr login --name acrflashsupersetprod

## 📞 Support

cd docker

- **Documentation**: Start with [docs/README.md](docs/README.md)docker build -t acrflashsupersetprod.azurecr.io/superset:latest .

- **Common Issues**: Check [troubleshooting guides](docs/troubleshooting/)docker push acrflashsupersetprod.azurecr.io/superset:latest

- **Architecture**: Review [architecture overview](docs/reference/architecture.md)```

- **Security**: Follow [security best practices](docs/reference/security.md)

#### 3. Deploy Application with Helm

## 📄 License

```bash

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.az aks get-credentials \

  --resource-group rg-flash-superset-prod \

---  --name aks-flash-superset-prod



**Project**: Apache Superset on AKS with Azure Databricks  cd helm

**Version**: 1.0  helm dependency update

**Last Updated**: October 29, 2025  

**Maintainer**: DevOps Teamhelm upgrade --install superset . \
  --namespace superset \
  --values values.yaml \
  --values values-production.yaml \
  --create-namespace \
  --wait
```

## ⚙️ Configuration

### Environment-Specific Configuration

- **Dev**: `terraform/environments/dev.tfvars`, `helm/environments/dev/values.yaml`
- **Staging**: `terraform/environments/staging.tfvars`, `helm/environments/staging/values.yaml`
- **Prod**: `terraform/environments/prod.tfvars`, `helm/values-production.yaml`

### Azure Active Directory OAuth Setup

1. Register application in Azure AD
2. Configure redirect URLs
3. Create client secret
4. Add secrets to Azure Key Vault
5. Update Helm values with client ID and tenant ID

See [DEPLOYMENT.md](DEPLOYMENT.md#security-configuration) for details.

### Databricks Connection

Connect to Azure Databricks using:

```
databricks+pyodbc://token:<PERSONAL_ACCESS_TOKEN>@<HOST>:443/default?driver=ODBC+Driver+17+for+SQL+Server
```

##  Troubleshooting

### Common Issues

**Pods not starting:**
```bash
kubectl describe pod -n superset -l app=superset
kubectl logs -n superset -l app=superset
```

**Database connection issues:**
```bash
kubectl exec -n superset deployment/superset -- \
  python -c "from superset import db; db.engine.connect()"
```

**Helm deployment failures:**
```bash
helm list -n superset
helm status superset -n superset
```

See [docs/troubleshooting.md](docs/troubleshooting.md) for more solutions.

## 🔒 Security

- ✅ Azure AD OAuth2 authentication
- ✅ Kubernetes RBAC enabled
- ✅ Network policies configured
- ✅ Secrets stored in Azure Key Vault
- ✅ Container image scanning
- ✅ Pod security contexts
- ✅ TLS/HTTPS with Let's Encrypt

## 📈 Roadmap

- [ ] Horizontal Pod Autoscaler based on custom metrics
- [ ] Multi-region deployment
- [ ] Automated backup to Azure Blob Storage
- [ ] Performance tuning guide

## 🤝 Contributing

1. Create a feature branch: `git checkout -b feature/amazing-feature`
2. Commit your changes: `git commit -m 'Add amazing feature'`
3. Push to branch: `git push origin feature/amazing-feature`
4. Create a Pull Request in Azure Repos

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Support

- **Internal Wiki**: [Link to your confluence/wiki]
- **Email**: your-team@your-domain.com
- **Azure DevOps**: [Project Board](https://dev.azure.com/your-org/Flash-Superset)
- **Teams Channel**: Flash Superset Support

## 🙏 Acknowledgments

- [Apache Superset](https://superset.apache.org/) team
- [Azure Kubernetes Service](https://azure.microsoft.com/services/kubernetes-service/) documentation
- [Helm Charts](https://helm.sh/) community# Testing GitHub Actions CI Pipeline
