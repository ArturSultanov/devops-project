variable "project_name" { type = string }
variable "vpc_cidr" { type = string }
variable "private_subnet_1_cidr" { type = string }
variable "private_subnet_2_cidr" { type = string }
variable "public_subnet_1_cidr" { type = string }
variable "public_subnet_2_cidr" { type = string }
variable "region" { type = string }
variable "zone_1" { type = string }
variable "zone_2" { type = string }
variable "eks_name" { type = string }
variable "eks_version" { type = string }
variable "instance_types" { type = list(string) }
variable "capacity_type" { type = string }

variable "pod_identity_version" { type = string }
variable "ebs_csi_version" { type = string }
variable "lbc_release_version" { type = string }
variable "metrics_server_version" { type = string }
