variable "region" {
  default     = "us-east-1"
  description = "This has been defined the region"
}
variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  default     = "10.0.0.0/16"
}