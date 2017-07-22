
# Stores current account and user data
data "aws_caller_identity" "current" {}

variable "aws_region" {
  description = "AWS Region"
}

variable "aws_key_name" {
  description = "SSH Key Name"
  default = "slapula-bigzetatest"
}

variable "environment_name" {
  default = "staging"
}

variable "asg_instance_type" {
  default = "t2.micro"
}

variable "asg_instance_ami" {
  default = "ami-1e299d7e"
}

variable "vpc_cidr" {
  description = "VPC netblock"
  default = "10.0.0.0/16"
}

variable "private_subnet_cidr" {
  description = "VPC private subnet"
  default = "10.0.0.0/24"
}
