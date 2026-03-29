terraform {
  required_version = ">= 1.10"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.38.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.1.0"
    }
  }

  backend "s3" {
    bucket = "artursultanov-demo-s3-bucket-940531747801-us-east-1-an"
    key    = "devops-demo/terraform.tfstate"
    region = "us-east-1"
    # https://developer.hashicorp.com/terraform/language/backend/s3#enabling-s3-state-locking
    use_lockfile = true
    # https://docs.aws.amazon.com/AmazonS3/latest/userguide/UsingServerSideEncryption.html 
    encrypt = true
  }
}

provider "aws" {
  region = local.region
}

data "aws_eks_cluster" "eks" {
  name = aws_eks_cluster.eks.name
}

data "aws_eks_cluster_auth" "eks" {
  name = aws_eks_cluster.eks.name
}

provider "helm" {
  kubernetes = {
    host                   = data.aws_eks_cluster.eks.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.eks.token
  }
}
