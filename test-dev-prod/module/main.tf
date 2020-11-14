### Modules
module "dev" {
    source = "../resources"
    instance_name = "dev_instance"
}

module "test" {
    source = "../resources"
    instance_name = "TEST_instance"
}

module "prod" {
    source = "../resources"
    instance_name = "PrOd_instance"
}

### S3 Backend
terraform {
  backend "s3" {
    bucket = "s3-terraform-state-bucker-dspv1"
    key    = "terraform/test-dev-prod/ec2.tfstate"
    region = "eu-central-1"
  }
}