provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project    = "Bastion Host"
      Repository = "https://github.com/felipelaptrin/bastion-host"
    }
  }
}

