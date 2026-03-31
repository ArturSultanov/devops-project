# GEMINI.md - Project Context

## Project Overview
This project is an Infrastructure-as-Code (IaC) and Kubernetes (K8s) deployment codebase designed to provision and manage a WordPress application on AWS EKS using a highly modular, corporate-grade architecture.

### Main Technologies:
- **Infrastructure**: Terraform (>= 1.10) with AWS, Helm, and Kubernetes providers.
- **Cloud Platform**: AWS (EKS v1.35, VPC, S3 for state backend).
- **Container Orchestration**: Kubernetes (EKS managed).
- **Deployment Management**: Kustomize (components and overlays).
- **CI/CD**: GitHub Actions for automated Terraform, Kustomize, and YAML validation.

### Architecture:

#### 1. Infrastructure Layer (`infra/`)
The infrastructure follows the **Environment Isolation** pattern with reusable modules.

*   **Modules (`infra/modules/`)**: Self-contained, reusable building blocks:
    *   **`network/`**: VPC, Subnets (Public/Private), NAT Gateway, IGW, Route Tables.
    *   **`eks/`**: Managed EKS cluster, IAM roles (cluster/nodes), and Spot instance worker nodes.
    *   **`addons/`**: Modular sub-modules for EKS features:
        *   **`pod_identity/`**: EKS Pod Identity Agent (required by other addons).
        *   **`ebs_csi/`**: EBS CSI Driver for persistent storage.
        *   **`load_balancer/`**: AWS Load Balancer Controller (via Helm).
        *   **`metrics_server/`**: Metrics Server (via Helm) for HPA support.

*   **Environments (`infra/env/`)**: Specific instances of the infrastructure:
    *   **`dev/`**: The development environment orchestrator. Uses `terraform.tfvars` for configuration and unique state isolation in S3 (`dev/terraform.tfstate`).

#### 2. Application Layer (`k8s/`)
The application is deployed into the `devops-demo--wordpress` namespace.
- **Components (`k8s/components/wordpress-app/`)**: Modular manifests for WordPress, MySQL (StatefulSet), and storage.
- **Overlays (`k8s/overlays/`)**: Environment-specific configurations (e.g., `devops-demo-eks-aws-us-east-1`).

---

## Building and Running

### Infrastructure (Terraform)
To manage the infrastructure, navigate to the environment directory:
```bash
cd infra/env/dev
terraform init
terraform plan
terraform apply
```
*Note: The S3 backend is configured in `backend.tf` and requires AWS credentials.*

### Application (Kustomize)
To build and inspect the Kubernetes manifests:
```bash
# Build a specific overlay
kustomize build k8s/overlays/devops-demo-eks-aws-us-east-1/

# Apply to cluster
kustomize build k8s/overlays/devops-demo-eks-aws-us-east-1/ | kubectl apply -f -
```

---

## Development Conventions

### Infrastructure
- **Modularity**: All new features must be added as modules in `infra/modules/`.
- **Isolation**: Never share state files between environments. Use unique S3 keys.
- **Variable Injection**: Environment-specific data (instance types, versions) must stay in `.tfvars` files.
- **Dependency Management**: Use explicit `depends_on` at the module level in `main.tf` to handle EKS bootstrap race conditions.
- **Versioning**: Pin all provider versions in `versions.tf` and addon versions in `.tfvars`.

### Kubernetes
- **Namespacing**: Managed within overlays or top-level kustomizations.
- **Autoscaling**: HPA is required for the WordPress frontend (monitors CPU).
- **Storage**: Use `gp3` storage class via the EBS CSI driver.

### CI/CD (GitHub Actions)
- **Validation**: Every PR triggers Terraform formatting/validation and Kustomize build checks.
- **Linting**: Strict YAML linting is enforced for all manifest files.

---

## Key Directories and Files
- `infra/modules/`: Reusable Terraform logic.
- `infra/env/dev/`: Development environment entry point.
- `k8s/components/`: Core application modules.
- `k8s/overlays/`: Environment-specific configurations.
- `infra/env/dev/terraform.tfvars`: Central place for environment-specific variables.
