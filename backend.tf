terraform {
  backend "s3" {
    bucket = "mydemoecstest1"
    key    = "dev/ecs/terraform.tfstate"
    region = "us-east-1"
  }
}
