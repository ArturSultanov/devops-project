# DevOps Project: Scalable WordPress on AWS EKS

This project provides a demo presentation of Infrastructure-as-Code (IaC) and Kubernetes deployment for a WordPress application connected to a MySQL database. It leverages AWS managed services and Terraform for infrastructure provisioning, following a modular, environment-isolated approach.

---

## Project Structure

The project is separated into two main parts: Terraform modules and Kubernetes manifests. 

### AWS Infrastructure (Terraform)
The infrastructure is provisioned on AWS using Terraform providers and follows a modular design and environment isolation pattern.

Infrastructure components are placed inside the [infra/](./infra/) directory, where the [infra/modules/](./infra/modules/) sub-directory is dedicated to reusable modules. These modules are used in the [infra/env/](./infra/env/) sub-directories, which are dedicated to different infrastructure environments such as "dev", "preprod", "prod", etc.

The directory structure is as follows:

```
infra/
├── env/
│   └── dev/
└── modules
    ├── addons/
    │   ├── ebs_csi/
    │   ├── load_balancer/
    │   ├── metrics_server/
    │   └── pod_identity/
    ├── eks/
    └── network/
```

#### Terraform Modules 

The following section describes each individual Terraform module presented or used in this project:

- [infra/modules/network/](./infra/modules/network/): Provisions the foundational networking infrastructure, including a VPC, public/private subnets across multiple AZs, a NAT Gateway for private egress, and an Internet Gateway.
- [infra/modules/eks/](./infra/modules/eks/): Configures the Amazon EKS cluster control plane, IAM roles, and a managed node group.
- [infra/modules/addons/pod_identity/](./infra/modules/addons/pod_identity/): Deploys the EKS Pod Identity Agent, which simplifies how Kubernetes applications consume AWS IAM permissions.
- [infra/modules/addons/ebs_csi/](./infra/modules/addons/ebs_csi/): Installs the Amazon EBS CSI driver as an EKS addon, enabling dynamic provisioning of EBS volumes for persistent storage.
- [infra/modules/addons/load_balancer/](./infra/modules/addons/load_balancer/): Deploys the AWS Load Balancer Controller using Helm to manage Elastic Load Balancers (ALB/NLB) via Kubernetes Ingress and Service resources.
- [infra/modules/addons/metrics_server/](./infra/modules/addons/metrics_server/): Provisions the Kubernetes Metrics Server via Helm, which is required for the Horizontal Pod Autoscaler (HPA) to function.

#### Terraform Environment

The [infra/env/dev/](./infra/env/dev/) directory contains the configuration for the development environment. It defines the following:

- Backend: `S3` bucket for storing the Terraform state file. 
- Project Region: `us-east-1`
- Networking: A dedicated VPC with 4 subnets (2 public, 2 private) distributed across two AZs (`us-east-1a`, `us-east-1b`).
- EKS Cluster: Managed EKS cluster running version `1.35` with compute provided by cost-efficient `SPOT` instances of `c7i-flex.large` or `m7i-flex.large` types.
- Versions: Centralized management of EKS addon and Helm chart versions in `terraform.tfvars`, and provider versions in `versions.tf`.

Currently, only the `dev` environment is represented. Nevertheless, the configuration is designed to be reusable, and the principle remains the same for other environments.

---

### Kubernetes Resources (Kustomize)

The Kubernetes resources are organized in a modular Kustomize structure and designed to be reusable.

Kubernetes manifests are placed inside the [k8s/](./k8s/) directory, where the [k8s/components/](./k8s/components/) sub-directory is dedicated to reusable components. These components are used in the [k8s/overlays/](./k8s/overlays/) sub-directories, which are dedicated to resources of the target cluster.

The directory structure is as follows:

```
k8s/
├── components/
│   └── wordpress-app/
│       ├── kustomization.yaml
│       ├── ns.yaml
│       ├── database/
│       ├── storage/
│       └── wordpress/
└── overlays/
    └── devops-demo-eks-aws-us-east-1/
```

#### Kubernetes Components 

The following section describes each individual Kubernetes resource and its purpose:

- [k8s/components/wordpress-app/](./k8s/components/wordpress-app/): The core application bundle.
    - `ns.yaml`: Defines the `devops-demo--wordpress` namespace to provide resource isolation and a clear boundary for the application.
    - `kustomization.yaml`: Orchestrates the assembly of the namespace, database, storage, and WordPress sub-components.

    - [database/](./k8s/components/wordpress-app/database/): Manages the persistence layer.
        - `statefulset.yaml`: Deploys MySQL with a stable network identity and persistent volume mapping. This is critical for databases to ensure data consistency and stable hostnames across pod restarts.
        - `service.yaml`: A standard ClusterIP service that provides a stable internal DNS name for WordPress to reach the database.
        - `service-headless.yaml`: A headless service required by the StatefulSet to control the domain of the database pods.
        - `kustomization.yaml`: Applies common labels (`app: mysql`) to all database resources for consistent selector targeting.

    - [storage/](./k8s/components/wordpress-app/storage/): Handles dynamic volume provisioning.
        - `storageclass.yaml`: Configures the `gp3` StorageClass using the `ebs.csi.aws.com` provisioner. It enables the automatic creation of AWS EBS volumes with a `Retain` deletion policy instead of the default `Delete` policy.
        - `kustomization.yaml`: Manages the storage resource configuration.

    - [wordpress/](./k8s/components/wordpress-app/wordpress/): Manages the application frontend.
        - `deployment.yaml`: Defines the WordPress pod template, replica count, and resource limits. It ensures the application remains available and handles updates via a rolling strategy.
        - `configmap.yaml`: Stores non-sensitive application configuration (DB host, ports, site settings), separating environment-specific config from the container image.
        - `service.yaml`: Exposes the WordPress pods internally.
        - `ingress.yaml`: Configures the AWS Load Balancer Controller to provision an internet-facing Application Load Balancer (ALB) and route traffic to the WordPress service.
        - `hpa.yaml`: Implements the Horizontal Pod Autoscaler, automatically adjusting replica counts based on CPU and memory demand to handle traffic spikes.
        - `kustomization.yaml`: Bundles frontend resources and applies the `app: wordpress` label.

Currently, there is only one dedicated component, which is the WordPress application. Nevertheless, the principle remains the same for any other components or applications that can be shared across clusters. 

#### Kubernetes Overlays

The following section describes the environment-specific Kubernetes overlay:

- [k8s/overlays/devops-demo-eks-aws-us-east-1/](./k8s/overlays/devops-demo-eks-aws-us-east-1/): The target configuration for the development EKS cluster.
    - `kustomization.yaml`: Orchestrates the final manifest assembly for the `dev` environment.
    - Secret Generation: Generates Kubernetes Secrets from local `.env` files (e.g., `mysql-secrets.env` and `wordpress-secrets.env`) to ensure sensitive credentials aren't stored in plain text in the repository. (However, these **should not** be used in a production environment. Consider using Vault for storing secrets.)
    - Base Resource Mapping: References the reusable `wordpress-app` component to build the final environment-specific configuration.

---

## WordPress Application Overview

This section describes the application architecture and how it demonstrates the principles of **Infrastructure as Code (IaC)** and **Kustomize modularity**.

### How it Works

The application follows a classic two-tier architecture:
1.  **Frontend (WordPress)**: A stateless deployment of WordPress using Nginx. It is exposed to the internet via an **AWS Application Load Balancer (ALB)**, managed by the AWS Load Balancer Controller.
2.  **Backend (MySQL)**: A stateful database layer using MySQL. It uses **EBS (gp3)** for persistent storage, managed by the EBS CSI Driver.

**Key Operational Features:**
- **Traffic Flow**: `User` -> `ALB` -> `WordPress Pods`. The ALB routes traffic directly to Pod IPs, bypassing the overhead of standard Kubernetes service proxying where possible.
- **Data Persistence**: MySQL data is stored in AWS EBS volumes. Even if the database pod is rescheduled to a different node, the volume is automatically re-attached, ensuring zero data loss.
- **Scalability**: The **Horizontal Pod Autoscaler (HPA)** monitors the CPU and memory usage of WordPress pods and automatically scales the number of replicas (from 1 to 8) to handle varying traffic loads.
- **Resilience**: Liveness, readiness, and startup probes ensure that traffic only reaches healthy pods and that failing pods are automatically restarted.

### IaC and Modular Approach

This project is a prime example of modern **Infrastructure as Code (IaC)**, where every component—from the VPC and EKS cluster to the WordPress application—is defined as code.

#### 1. Infrastructure as Code (Terraform)

- **Environment Isolation**: The `infra/env/` structure ensures that different stages (dev, prod) are isolated. Changes in one environment do not impact others unless explicitly applied.
- **Resource Reusability**: By using modules in `infra/modules/`, we avoid code duplication. For example, the `eks` module can be reused across different projects or environments with different parameters.

#### 2. Kustomize Modular Approach

The Kubernetes layer uses **Kustomize** to implement a "Base and Overlay" pattern:
- **Components (`k8s/components/`)**: These are the "building blocks." They define generic resources (Deployments, Services, etc.) needed for the app to run. They are kept free of environment-specific details.
- **Overlays (`k8s/overlays/`)**: This is where environment-specific logic lives. Overlays "import" components and apply patches (e.g., specific replica counts, namespace overrides, or secret generation).
- **Separation of Concerns**: Developers work on components to change the app's architecture, while DevOps engineers work on overlays to change how the app is deployed to a specific cluster. This modularity makes the codebase easy to maintain and scale.

---

## CI/CD Workflows (GitHub Actions)

The project includes automated validation workflows to ensure code quality and prevent regressions. These are located in:

```
.github
└── workflows
    ├── kustomization-validaton.yaml
    ├── terraform-validation.yaml
    ├── yaml-lint.yaml
    └── yamllint.yaml
```

### Workflows: 

- Terraform Validation [terraform-validation.yaml](./.github/workflows/terraform-validation.yaml): Performs validation of the Terraform files by running `terraform fmt -check` and `terraform plan` commands.

- Kubernetes Validation [kustomization-validaton.yaml](./.github/workflows/kustomization-validaton.yaml): Executes `kustomize build` for key components. It verifies that all resource references, patches, and secret generators are correctly configured and that the final manifest can be successfully generated.

- YAML Linting [yaml-lint.yaml](.github/workflows/yaml-lint.yaml): Scans all `.yaml` and `.yml` files in the repository. It uses `yamllint` with a custom configuration to enforce standards.

---

## How to Deploy

### Prerequisites

- AWS CLI (v2.x) configured with appropriate permissions.
- Terraform (>= 1.10).
- kubectl (v1.30+) and kustomize (v5.x+) installed.

### 1. Provision Infrastructure

```bash
cd infra/env/dev
terraform init
terraform plan
terraform apply -auto-approve
```

### 2. Configure Access

```bash
# Get the connection command from Terraform outputs
terraform output update_kubeconfig_command | xargs bash
```

### 3. Prepare Application Secrets

Before deploying, create the environment files required by Kustomize for sensitive data:

```bash
cd k8s/overlays/devops-demo-eks-aws-us-east-1/
```
Create `mysql-secrets.env` (see example [mysql-secrets-example.env](./k8s/overlays/devops-demo-eks-aws-us-east-1/mysql-secrets-example.env)):

```text
MYSQL_ROOT_PASSWORD=RootPasswordExample
MYSQL_USER_PASSWORD=UserPasswordExample
```

Create `wordpress-secrets.env` (see example [wordpress-secrets-example.env](./k8s/overlays/devops-demo-eks-aws-us-east-1/wordpress-secrets-example.env)):

```text
ADMIN_PASSWORD=AdminPasswordExample
```

### 4. Deploy Application

```bash
# Deploy using Kustomize
kubectl apply -k k8s/overlays/devops-demo-eks-aws-us-east-1/
```

### 5. Accessing WordPress

Once deployed, you can find the Application Load Balancer (ALB) URL by running:

```bash
kubectl get ingress -n devops-demo--wordpress
```
Access the Admin Dashboard at: `http://<ALB_URL>/wp-admin`

Login Credentials:
* Username: `admin` (as defined in `configmap.yaml`)
* Password: The value provided in `wordpress-secrets.env`.

---

## Infrastructure Cleanup


```bash
# 1. Delete Kubernetes resources (cleanup Load Balancer; MySQL EBS volumes will remain)
kubectl delete -k k8s/overlays/devops-demo-eks-aws-us-east-1/

# 2. Destroy AWS Infrastructure
cd infra/env/dev
terraform destroy -auto-approve
```

---

## Performance Benchmarking

Resource utilization benchmarks under various load levels (using `hey`):

| Load Level | Requests/sec | Concurrency | WordPress CPU | MySQL CPU | Node CPU Avg |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Low | 1 | 5 | ~160m | ~40m | ~7% |
| Medium | 5 | 5 | ~640m | ~130m | ~22% |
| High | 20 | 50 | ~1782m | ~297m | ~58% |

