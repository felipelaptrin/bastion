variable "aws_region" {
  description = "Region that AWS resources will be deployed"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "VPC CIDR to use"
  type        = string
  default     = "10.123.0.0/16"
}

variable "azs" {
  description = "Number of AZs to use in the VPC"
  type        = number
  default     = 3
}

variable "instance_type" {
  description = "Defines the instance type of the EC2 bastion host"
  type        = string
  default     = "t3.nano"
}
