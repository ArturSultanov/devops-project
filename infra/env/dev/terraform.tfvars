# --- Global Settings ---
project_name = "devops-demo"
region       = "us-east-1"

# --- Networking Settings ---
vpc_cidr = "10.0.0.0/16"
private_subnet_1_cidr = "10.0.0.0/24"
private_subnet_2_cidr = "10.0.1.0/24"
public_subnet_1_cidr = "10.0.2.0/24"
public_subnet_2_cidr = "10.0.3.0/24"
zone_1   = "us-east-1a"
zone_2   = "us-east-1b"

# --- EKS Cluster Settings ---
eks_name              = dev
eks_version           = "1.35"
instance_types = ["c7i-flex.large", "m7i-flex.large"]
capacity_type  = "SPOT"

# --- Addons Versions ---
pod_identity_version  = "v1.3.10-eksbuild.2"
ebs_csi_version       = "v1.57.1-eksbuild.1"
lbc_release_version   = "3.1.0"
metrics_server_version = "3.13.0"
