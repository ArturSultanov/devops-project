# GEMINI.md - Project Context

## Project Overview
This project is an Infrastructure-as-Code (IaC) and Kubernetes (K8s) deployment codebase designed to provision and manage a scalable WordPress application on AWS EKS using a highly modular, environment-isolated architecture.

### Main Technologies:
- **Infrastructure**: Terraform (>= 1.10) with AWS, Helm, and Kubernetes providers.
- **Cloud Platform**: AWS (EKS v1.35, VPC, S3 for state backend).
- **Container Orchestration**: Kubernetes (EKS managed).
- **Deployment Management**: Kustomize (components and overlays).
- **CI/CD**: GitHub Actions for automated Terraform formatting/plan, Kustomize build validation, and YAML linting.

### Architecture:

#### 1. Infrastructure Layer (`infra/`)
Follows the **Environment Isolation** pattern with reusable modules.

*   **Modules (`infra/modules/`)**:
    *   **`network/`**: VPC, 4 subnets (2 public, 2 private) across multiple AZs, NAT Gateway, IGW.
    *   **`eks/`**: Managed EKS cluster, IAM roles, and managed node groups using cost-efficient **SPOT instances** (`c7i-flex.large` or `m7i-flex.large`).
    *   **`addons/`**:
        *   **`pod_identity/`**: EKS Pod Identity Agent (required for IAM-to-Pod permissions).
        *   **`ebs_csi/`**: Amazon EBS CSI Driver for persistent storage.
        *   **`load_balancer/`**: AWS Load Balancer Controller (ALB/NLB management).
        *   **`metrics_server/`**: Required for Horizontal Pod Autoscaler (HPA).

*   **Environments (`infra/env/`)**:
    *   **`dev/`**: Development environment in `us-east-1`. Uses S3 backend for state and `terraform.tfvars` for version/instance configuration.

#### 2. Application Layer (`k8s/`)
Uses a "Base and Overlay" pattern for modularity.

*   **Components (`k8s/components/wordpress-app/`)**:
    *   **`wordpress/`**: Stateless frontend with Nginx, HPA (1-8 replicas), and ALB Ingress.
    *   **`database/`**: Stateful MySQL using `StatefulSet` for stable network identity.
    *   **`storage/`**: `gp3` StorageClass with `Retain` policy via EBS CSI driver.
*   **Overlays (`k8s/overlays/`)**:
    *   **`devops-demo-eks-aws-us-east-1`**: Environment-specific patches and **Secret Generation** from `.env` files.

---

## Operational Features
- **Scalability**: HPA automatically scales WordPress replicas (1 to 8) based on CPU/Memory.
- **Persistence**: MySQL data is stored on AWS EBS volumes; volumes automatically re-attach if pods are rescheduled.
- **Traffic Management**: AWS ALB routes traffic directly to Pod IPs, bypassing standard service proxy overhead.
- **Resilience**: Configured with Liveness, Readiness, and Startup probes.

---

## Building and Running

### 1. Infrastructure (Terraform)
```bash
cd infra/env/dev
terraform init
terraform apply
```

### 2. Prepare Secrets
Create `.env` files in `k8s/overlays/devops-demo-eks-aws-us-east-1/`:
- `mysql-secrets.env`: `MYSQL_ROOT_PASSWORD`, `MYSQL_USER_PASSWORD`.
- `wordpress-secrets.env`: `ADMIN_PASSWORD`.

### 3. Application (Kustomize)
```bash
# Apply to cluster
kubectl apply -k k8s/overlays/devops-demo-eks-aws-us-east-1/
```

### 4. Cleanup
```bash
# Delete K8s resources first to clean up ELB/EBS
kubectl delete -k k8s/overlays/devops-demo-eks-aws-us-east-1/
# Destroy infrastructure
terraform destroy
```

---

## Development Conventions

### Infrastructure
- **Modularity**: New features must be modules in `infra/modules/`.
- **Isolation**: Never share state files; use unique S3 keys per environment.
- **Versioning**: Pin provider versions in `versions.tf` and addon/chart versions in `.tfvars`.

### Kubernetes
- **Namespacing**: Managed within components (`ns.yaml`) and orchestrated by overlays.
- **Secrets**: Use Secret Generator in overlays for local dev; recommend Vault for production.
- **Storage**: Always use `gp3` with the EBS CSI driver for performance and cost.

---

## Key Directories and Files
- `infra/modules/`: Reusable Terraform logic.
- `infra/env/dev/`: Development environment entry point.
- `k8s/components/`: Generic application building blocks.
- `k8s/overlays/`: Environment-specific configurations and patches.
