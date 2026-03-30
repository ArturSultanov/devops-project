resource "aws_iam_role" "ebs_csi" {
  name = "${local.project_name}-ebs-csi"

  assume_role_policy = <<JSON
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "sts:AssumeRole",
          "sts:TagSession"
        ],
        "Principal": {
          "Service": "pods.eks.amazonaws.com" 
        }
      }
    ] 
  }
  JSON
}

resource "aws_iam_role_policy_attachment" "AmazonEBSCSIDriverPolicy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi.name
}

#  resource "aws_eks_pod_identity_association" "ebs_csi" {
#    cluster_name    = aws_eks_cluster.eks.name
#    namespace       = "kube-system"
#    service_account = "ebs-csi-controller-sa"
#    role_arn        = aws_iam_role.ebs_csi.arn
#  }
