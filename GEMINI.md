# GEMINI.md - Project Context

## Project Overview
This project is an Infrastructure-as-Code (IaC) and Kubernetes (K8s) deployment codebase designed to provision and manage a WordPress application on AWS EKS.

### Main Technologies:
- **Infrastructure**: Terraform (>= 1.10) using AWS and Helm providers.
- **Cloud Platform**: AWS (EKS v1.35, VPC, S3 for state backend).
- **Container Orchestration**: Kubernetes (EKS managed).
- **Deployment Management**: Kustomize (components and overlays).
- **CI/CD**: GitHub Actions for automated Terraform and Kustomize validation.

### Architecture:
1.  **Infrastructure Layer (`infra/terraform/`)**: Configures the underlying AWS resources including VPC, subnets, NAT gateways, EKS cluster, worker nodes (using Spot instances), and necessary IAM policies.
2.  **Application Layer (`k8s/`)**:
    -   **Components (`k8s/components/wordpress-app/`)**: Core manifests for WordPress, MySQL (StatefulSet), storage classes, and services.
    -   **Overlays (`k8s/overlays/`)**: Environment-specific configurations (e.g., `devops-demo-eks-aws-us-east-1`).

---

## Building and Running

### Infrastructure (Terraform)
To manage the infrastructure, navigate to `infra/terraform/`:
```bash
cd infra/terraform
terraform init
terraform plan
terraform apply
```
*Note: The S3 backend is configured in `providers.tf` and requires appropriate AWS credentials.*

### Application (Kustomize)
To build and inspect the Kubernetes manifests:
```bash
# Build a specific overlay
kustomize build k8s/overlays/devops-demo-eks-aws-us-east-1/

# Apply to cluster (requires kubectl and cluster access)
kustomize build k8s/overlays/devops-demo-eks-aws-us-east-1/ | kubectl apply -f -
```

---

## Development Conventions

### Infrastructure
- **Provider Versioning**: AWS provider (~> 6.38.0), Helm provider (~> 3.1.0).
- **Backend**: S3 with state locking and encryption enabled.
- **Locals**: Use `locals.tf` for region, naming, and instance type configurations.
- **Formatting**: Always run `terraform fmt` before committing.

### Kubernetes
- **Structure**: Follow the Kustomize "components" pattern for modularity.
- **Namespacing**: Managed within the overlays or top-level kustomization files.
- **Secrets**: Managed via `secretGenerator` in `kustomization.yaml` (using `.env` files).

### CI/CD (GitHub Actions)
- **Terraform Validation**: Triggered on pull requests for `.tf` files. Checks formatting and validates configuration (runs `init -backend=false` for validation).
- **Kustomize Validation**: Triggered on pull requests for `k8s/**` files. Ensures the kustomization build succeeds.
- **Linting**: General YAML linting is enforced via `yaml-lint.yaml` and `yamllint.yaml`.

---

## Key Directories and Files
- `infra/terraform/`: Terraform configuration files.
- `k8s/components/`: Core application modules.
- `k8s/overlays/`: Environment-specific configurations.
- `.github/workflows/`: CI pipeline definitions.
- `infra/terraform/locals.tf`: Central place for infrastructure variables.
- `infra/terraform/providers.tf`: Backend and provider configuration.
