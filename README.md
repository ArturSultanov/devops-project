# DevOps Project: Scalable WordPress on AWS EKS

This project provides a production-grade Infrastructure-as-Code (IaC) and Kubernetes deployment for a WordPress application. It leverages AWS managed services, Terraform for infrastructure provisioning, and Kustomize for Kubernetes manifest management.

---

## Architecture Overview

### AWS Infrastructure (Terraform)
The infrastructure is designed for high availability, security, and cost-efficiency.

#### 1. Networking (VPC)
- **AWS VPC**: A dedicated Virtual Private Cloud with a `10.0.0.0/16` CIDR block.
- **Subnets**:
    - **Public Subnets (x2)**: Hosted in different AZs for high availability. They contain the NAT Gateways and the Application Load Balancer (ALB).
    - **Private Subnets (x2)**: Hosted in different AZs. These are where the EKS worker nodes reside, isolated from direct internet access.
- **Internet Gateway (IGW)**: Provides internet access for resources in public subnets.
- **NAT Gateways**: Allow worker nodes in private subnets to reach the internet for updates and image pulls while preventing inbound connections.

#### 2. Compute (EKS)
- **EKS Cluster**: A managed Kubernetes control plane (v1.35).
- **Managed Node Groups**: 
    - Uses **Amazon Linux 2** worker nodes.
    - Optimized for cost using **SPOT instances** (`c7i-flex.large`, `m7i-flex.large`).
    - Configured with auto-scaling (Min: 1, Desired: 2, Max: 5).
- **IAM Roles & Policies**: Fine-grained access control for the cluster and worker nodes (e.g., `AmazonEKSClusterPolicy`, `AmazonEKSWorkerNodePolicy`, `AmazonEKS_CNI_Policy`).

#### 3. Storage & Add-ons
- **EBS CSI Driver**: Installed via Terraform to manage Amazon EBS volumes for persistent storage.
- **AWS EKS Add-ons**: Includes `vpc-cni`, `kube-proxy`, and `coredns`.

---

### Kubernetes Resources (Kustomize)
The application is deployed into the `devops-demo--wordpress` namespace using a modular Kustomize structure.

#### 1. WordPress Application
- **Deployment**: Runs the `bitnami/wordpress-nginx` image.
- **HPA (Horizontal Pod Autoscaler)**: Automatically scales the WordPress pods based on CPU utilization.
- **Probes**: Configured with `startupProbe`, `livenessProbe`, and `readinessProbe` to ensure high availability and self-healing.
- **Service**: A standard Service to expose WordPress pods internally.
- **Ingress**: Uses the **AWS Load Balancer Controller** to provision an Application Load Balancer (ALB), providing a single entry point for traffic.

#### 2. Database (MySQL)
- **StatefulSet**: Manages the MySQL database pods, ensuring stable network identifiers and persistent storage.
- **Headless Service**: Used for service discovery between WordPress and MySQL.
- **PersistentVolumeClaim (PVC)**: Requests 20Gi of `gp3` storage via the EBS CSI driver.

#### 3. Configuration & Secrets
- **ConfigMaps**: Store non-sensitive configuration for WordPress and Nginx.
- **Secrets**: Managed via `secretGenerator` in Kustomize, injecting database credentials and admin passwords from `.env` files into pods as environment variables.

---

## CI/CD Workflows (GitHub Actions)

This repository uses GitHub Actions to automate validation and maintain code quality:

1.  **Terraform Validation (`terraform-validation.yaml`)**:
    -   Triggered on PRs to `.tf` files.
    -   Runs `terraform fmt` to enforce style.
    -   Runs `terraform validate` to catch syntax or configuration errors.
2.  **Kustomize Validation (`kustomization-validaton.yaml`)**:
    -   Triggered on PRs to `k8s/` files.
    -   Executes `kustomize build` to ensure all manifests are valid and dependencies are resolved.
3.  **YAML Linting (`yaml-lint.yaml`, `yamllint.yaml`)**:
    -   Ensures all YAML files follow best practices and consistent formatting.

---

## Performance Benchmarking

Resource utilization benchmarks under various load levels (using `hey`):

| Load Level | Requests/sec | Concurrency | WordPress CPU | MySQL CPU | Node CPU Avg |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Low** | 1 | 5 | ~160m | ~40m | ~7% |
| **Medium** | 5 | 5 | ~640m | ~130m | ~22% |
| **High** | 20 | 50 | ~1780m | ~300m | ~58% |

---

## How to Deploy

### Prerequisites
- AWS CLI configured with appropriate permissions.
- Terraform >= 1.10.
- `kubectl` and `kustomize` installed.

### 1. Provision Infrastructure
```bash
cd infra/terraform
terraform init
terraform apply -auto-approve
```

### 2. Deploy Application
```bash
# Update kubeconfig to point to the new cluster
aws eks update-kubeconfig --region us-east-1 --name devops-demo-eks

# Deploy using Kustomize
kubectl apply -k k8s/overlays/devops-demo-eks-aws-us-east-1/
```

---

## Maintenance & Troubleshooting
- **Logs**: `kubectl logs -l app=wordpress -n devops-demo--wordpress`
- **Scaling**: `kubectl get hpa -n devops-demo--wordpress`
- **Infrastructure**: `terraform state list` to view managed AWS resources.
