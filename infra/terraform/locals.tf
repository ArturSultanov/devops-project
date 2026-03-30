locals {
  region       = "us-east-1"
  zone_1       = "us-east-1a"
  zone_2       = "us-east-1b"
  project_name = "devops-demo"
  eks_name     = "${local.project_name}-eks"
  eks_version  = "1.35"
  # Free tier: ["t3.micro", "t3.small", "c7i-flex.large", "m7i-flex.large"]
  worker_instance_types = ["c7i-flex.large", "m7i-flex.large"]
  worker_capacity_type  = "SPOT"
}
