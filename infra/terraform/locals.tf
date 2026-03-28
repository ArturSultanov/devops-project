locals {
  region               = "us-east-1"
  zone_1               = "us-east-1a"
  zone_2               = "us-east-1b"
  project_name         = "devops-demo"
  eks_name             = "devops-demo-eks"
  eks_version          = "1.35"
  worker_instance_type = "t3a.medium"
  worker_capacity_type = "ON_DEMAND"
}
