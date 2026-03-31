resource "aws_iam_role" "eks" {
  name = "${var.project_name}-eks-role"

  assume_role_policy = <<JSON
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "eks.amazonaws.com"
        }
      }
    ]
  }
  JSON
}

resource "aws_iam_role_policy_attachment" "eks" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks.name
}

resource "aws_eks_cluster" "eks" {
  name     = var.eks_name
  version  = var.eks_version
  role_arn = aws_iam_role.eks.arn

  vpc_config {
    endpoint_private_access = true
    endpoint_public_access  = true

  subnet_ids = var.private_subnets_ids 

  }

  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }

  depends_on = [aws_iam_role_policy_attachment.eks]
}

resource "aws_iam_role" "worker_nodes" {
  name = "${var.project_name}-eks-node"

  assume_role_policy = <<JSON
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        }
      }
    ]
  }
  JSON
}

# This policy allows Amazon EKS worker nodes to connect to Amazon EKS Clusters.
resource "aws_iam_role_policy_attachment" "amazoneksworkernodepolicy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.worker_nodes.name
}

# This policy provides the Amazon VPC CNI Plugin (amazon-vpc-cni-k8s) 
# the permissions it requires to modify the IP address configuration on EKS worker nodes.
resource "aws_iam_role_policy_attachment" "amazoneks_cni_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.worker_nodes.name
}

# Provides read-only access to Amazon EC2 Container Registry repositories.
resource "aws_iam_role_policy_attachment" "amazonec2containerregistryreadonly_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.worker_nodes.name
}

resource "aws_eks_node_group" "worker_nodes" {
  cluster_name    = aws_eks_cluster.eks.name
  version         = var.eks_version
  node_role_arn   = aws_iam_role.worker_nodes.arn
  node_group_name = "workers"

  capacity_type  = var.capacity_type
  instance_types = var.instance_types

  labels = {
    role = "worker"
  }

  subnet_ids = var.private_subnets_ids 

  scaling_config {
    desired_size = 2
    max_size     = 5
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.amazoneksworkernodepolicy_attachment,
    aws_iam_role_policy_attachment.amazoneks_cni_policy_attachment,
    aws_iam_role_policy_attachment.amazonec2containerregistryreadonly_attachment,
  ]
}
