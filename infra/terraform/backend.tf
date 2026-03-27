terraform {
  backend "s3" {
    bucket = "artursultanov-demo-s3-bucket-940531747801-us-east-1-an"
    key    = "devops-demo/terraform.tfstate"
    region = "us-east-1"
    # https://developer.hashicorp.com/terraform/language/backend/s3#enabling-s3-state-locking
    use_lockfile = true
    # https://docs.aws.amazon.com/AmazonS3/latest/userguide/UsingServerSideEncryption.html 
    encrypt = true
  }
}

