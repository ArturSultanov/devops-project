variable "project_name" { type = string }
variable "eks_name"        { type = string }
variable "eks_version"     { type = string }
variable "vpc_id"          { type = string }
variable "private_subnets_ids" { type = list(string) }
variable "instance_types"  { type = list(string) }
variable "capacity_type"   { type = string }
