module "vpc" {
  source          = "terraform-aws-modules/vpc/aws"
  version         = "5.16.0"
  name            = "bastion-terraform"
  azs             = local.azs
  cidr            = var.vpc_cidr
  private_subnets = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k + 4)]

  database_subnets                   = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k + 8)]
  create_database_subnet_route_table = true
  create_database_nat_gateway_route  = true

  enable_nat_gateway = true
  single_nat_gateway = true
}

module "bastion_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"

  name = "bastion-terraform-sg"

  vpc_id = module.vpc.vpc_id
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 65535
      protocol    = "tcp"
      description = "Allow all outbound traffic"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
}

module "bastion" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.7.1"

  name                   = "bastion-terraform"
  instance_type          = var.instance_type
  vpc_security_group_ids = [module.bastion_sg.security_group_id]
  subnet_id              = module.vpc.private_subnets[0]
  ignore_ami_changes     = false
  ami                    = data.aws_ami.ubuntu_latest.id

  create_iam_instance_profile = true
  iam_role_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  user_data = <<EOF
#!/bin/bash

echo "Installing SSM Agent"
sudo snap install amazon-ssm-agent --classic
sudo snap list amazon-ssm-agent
sudo snap start amazon-ssm-agent
sudo snap services amazon-ssm-agent
EOF
}


module "database_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"

  name = "database-terraform-sg"

  vpc_id = module.vpc.vpc_id
  ingress_with_source_security_group_id = [
    {
      from_port                = 5432
      to_port                  = 5432
      protocol                 = "tcp"
      description              = "Allow inbound traffic on default Postgres port"
      source_security_group_id = module.bastion_sg.security_group_id
    },
  ]
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 65535
      protocol    = "tcp"
      description = "Allow all outbound traffic"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
}

module "database" {
  source  = "terraform-aws-modules/rds/aws"
  version = "6.10.0"

  identifier = "database-terraform"
  db_name    = "main"

  engine               = "postgres"
  engine_version       = "14"
  family               = "postgres14"
  major_engine_version = "14"
  instance_class       = "db.t4g.large"
  allocated_storage    = 5

  username = "postgres"

  db_subnet_group_name   = module.vpc.database_subnet_group
  vpc_security_group_ids = [module.database_sg.security_group_id]

  skip_final_snapshot = true
  deletion_protection = false
}