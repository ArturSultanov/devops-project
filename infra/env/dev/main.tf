module "network" {
  source = "../../modules/network"

  project_name          = var.project_name
  vpc_cidr              = var.vpc_cidr
  private_subnet_1_cidr = var.private_subnet_1_cidr
  private_subnet_2_cidr = var.private_subnet_2_cidr
  public_subnet_1_cidr  = var.public_subnet_1_cidr
  public_subnet_2_cidr  = var.public_subnet_2_cidr
  region                = var.region
  zone_1                = var.zone_1
  zone_2                = var.zone_2
  eks_name              = var.eks_name
}

module "eks" {
  source = "../../modules/eks"

  project_name        = var.project_name
  eks_name            = var.eks_name
  eks_version         = var.eks_version
  vpc_id              = module.network.vpc_id
  private_subnets_ids = module.network.private_subnet_ids
  instance_types      = var.instance_types
  capacity_type       = var.capacity_type
}

module "pod_identity" {
  source        = "../../modules/addons/pod_identity"
  cluster_name  = module.eks.cluster_name
  addon_version = var.pod_identity_version
  depends_on    = [module.eks]
}

module "ebs_csi" {
  source        = "../../modules/addons/ebs_csi"
  project_name  = var.project_name
  cluster_name  = module.eks.cluster_name
  addon_version = var.ebs_csi_version
  depends_on    = [module.pod_identity]
}

module "load_balancer" {
  source          = "../../modules/addons/load_balancer"
  project_name    = var.project_name
  cluster_name    = module.eks.cluster_name
  vpc_id          = module.network.vpc_id
  release_version = var.lbc_release_version
  depends_on      = [module.pod_identity]
}

module "metrics_server" {
  source          = "../../modules/addons/metrics_server"
  release_version = var.metrics_server_version
  depends_on      = [module.eks]
}
