terraform {
  backend "s3" {
    bucket = "mydemoecstest2"
    key    = "dev/ecs/terraform.tfstate"
    region = "us-east-1"
  }
}
