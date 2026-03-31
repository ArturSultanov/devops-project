terraform {
  backend "s3" {
    bucket       = "artursultanov-demo-s3-bucket-940531747801-us-east-1-an"
    key          = "devops-demo/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }
}
