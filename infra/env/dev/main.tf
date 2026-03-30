module "network" {
  source = "../../modules/network/"

  project_name = var.project_name
  vpc_cidr = var.vpc_cidr 
  private_subnet_1_cidr = var.private_subnet_1_cidr 
  private_subnet_2_cidr = var.private_subnet_2_cidr
  public_subnet_1_cidr = var.public_subnet_1_cidr
  public_subnet_2_cidr = var.public_subnet_2_cidr
  region = var.region
  zone_1 = var.zone_1
  zone_2 = var.zone_2
  eks_name = var.eks_name
}

module "eks" {
  source         = "../../modules/eks"
}

module "pod_identity" {
  source         = "../../modules/addons/pod_identity/"
  depends_on = [module.eks]
}

module "ebs_csi" {
  source         = "../../modules/addons/ebs_csi/"
  depends_on = [module.pod_identity]
}
