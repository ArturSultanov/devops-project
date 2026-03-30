variable "project_name" { type = string }
variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}
variable "private_subnet_1_cidr" {
  type    = string
  default = "10.0.0.0/24"
}
variable "private_subnet_2_cidr" {
  type    = string
  default = "10.0.1.0/24"
}
variable "public_subnet_1_cidr" {
  type    = string
  default = "10.0.2.0/24"
}
variable "public_subnet_2_cidr" {
  type    = string
  default = "10.0.3.0/24"
}
variable "region" { type = string }
variable "zone_1" { type = string }
variable "zone_2" { type = string }
variable "eks_name" { type = string }
