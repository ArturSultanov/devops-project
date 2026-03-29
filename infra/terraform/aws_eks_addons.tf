resource "aws_eks_addon" "pod_identity" {
  cluster_name  = aws_eks_cluster.eks.name
  addon_name    = "eks-pod-identity-agent"
  addon_version = "v1.3.10-eksbuild.2"
  depends_on    = [aws_eks_node_group.worker_nodes]
}

resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name  = aws_eks_cluster.eks.name
  addon_name    = "aws-ebs-csi-driver"
  addon_version = "v1.57.1-eksbuild.1"
  # https://aws.amazon.com/blogs/containers/simplifying-iam-permissions-for-amazon-eks-addons-with-eks-pod-identity/
  pod_identity_association {
    service_account = "ebs-csi-controller-sa"
    role_arn        = aws_iam_role.ebs_csi.arn
  }
  depends_on = [aws_eks_addon.pod_identity]
}
