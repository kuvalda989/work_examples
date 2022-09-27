terraform {
  source = "tfr:///terraform-aws-modules/ec2-instance/aws?version=3.2.0"
}

include "root" {
  path = find_in_parent_folders()
}

dependencies {
  paths = ["../vpc", "../key-pair", "../security-groups"]
}


dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    vpc_id                    = "12435"
    public_subnets            = ["subnet-02f7e73ad39d3f"]
    default_security_group_id = "test_sg"
  }
}

dependency "key-pair" {
  config_path = "../key-pair"

  mock_outputs = {
    key_name = "mock_key"
  }
}

dependency "security-groups" {
  config_path = "../security-groups"

  mock_outputs = {
    security_group_id = "mock_key"
  }
}

inputs = {
  create                      = false
  name                        = "jump-host"
  ami                         = "ami-047e03b8591f2d48a"
  instance_type               = "t2.micro"
  subnet_id                   = dependency.vpc.outputs.public_subnets[0]
  associate_public_ip_address = true
  key_name                    = dependency.key-pair.outputs.key_name
  vpc_security_group_ids      = concat([dependency.security-groups.outputs.security_group_id], [dependency.vpc.outputs.default_security_group_id])
}
