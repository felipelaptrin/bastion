locals {
  azs                   = slice(data.aws_availability_zones.available.names, 0, var.azs)
  instance_architecture = contains(data.aws_ec2_instance_type.this.supported_architectures, "arm64") ? "arm64" : "x86_64"
}