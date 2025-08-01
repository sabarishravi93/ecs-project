terraform {
  backend "s3" {
    bucket = "mydemoecstest"
    key    = "dev/ecs/terraform.tfstate"
    region = "us-east-1"
  }
}
