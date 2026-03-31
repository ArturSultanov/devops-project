resource "aws_iam_role" "ebs_csi" {
  name = "${var.project_name}-ebs-csi"

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

resource "aws_iam_role_policy_attachment" "ebs_csi_driver_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi.name
}

resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name  = var.cluster_name
  addon_name    = "aws-ebs-csi-driver"
  addon_version = var.addon_version

  pod_identity_association {
    service_account = "ebs-csi-controller-sa"
    role_arn        = aws_iam_role.ebs_csi.arn
  }

  depends_on = [
    aws_iam_role_policy_attachment.ebs_csi_driver_policy_attachment
  ]
}
