data "aws_availability_zones" "available" {}

data "aws_ec2_instance_type" "this" {
  instance_type = var.instance_type
}

data "aws_ami" "ubuntu_latest" {
  most_recent = true
  owners      = ["099720109477"] # Canonical's AWS account ID (maintainer of Ubuntu)

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-*-${local.instance_architecture == "x86_64" ? "amd64" : "arm64"}-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["${local.instance_architecture}"]
  }
}
