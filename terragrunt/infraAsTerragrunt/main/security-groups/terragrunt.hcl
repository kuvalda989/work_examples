terraform {
  source = "tfr:///terraform-aws-modules/security-group/aws?version=4.4.0"
}

include "root" {
  path = find_in_parent_folders()
}

dependencies {
  paths = ["../vpc"]
}


dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    vpc_id = "12435"
  }
}


inputs = {

  name   = "jump-host-sg"
  vpc_id = dependency.vpc.outputs.vpc_id
  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "ssh access"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
}
