variable "project_name" { type = string }
variable "cluster_name" { type = string }
variable "vpc_id" { type = string }
variable "release_version" {
  type    = string
  default = "3.1.0"
}
