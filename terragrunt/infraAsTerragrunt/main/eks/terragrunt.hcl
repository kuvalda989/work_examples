terraform {
  source = "tfr:///terraform-aws-modules/eks/aws?version=17.20.0"

  after_hook "kubeconfig" {
    commands = ["apply"]
    execute  = ["bash", "-c", "terraform output --raw kubeconfig 2>/dev/null > ${get_terragrunt_dir()}/kubeconfig"]
  }

  after_hook "delete aws cni" {
    commands = ["apply"]
    execute  = ["bash", "-c", "kubectl --kubeconfig ${get_terragrunt_dir()}/kubeconfig -n kube-system --ignore-not-found=true --wait=true delete daemonset aws-node"]
  }

}

include "root" {
  path = find_in_parent_folders()
}

dependencies {
  paths = ["../vpc", "../key-pair"]
}


dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    vpc_id          = "12435"
    private_subnets = ["subnet-02f7e73ad39d3f63d", "subnet-02f7e73ad39d3f6ew", "subnet-02f7e73ad39d3f623"]
    public_subnets  = ["subnet-02f7e73ad39d3f", "subnet-02f7e73ad39d", "subnet-02f7e73ad39d"]
  }
}

dependency "key-pair" {
  config_path = "../key-pair"

  mock_outputs = {
    key_name       = "mock_key"
    public_subnets = ["subnet-02f7e73ad39d3f"]
  }
}


generate "provider-k8s" {
  path      = "provider-k8s.tf"
  if_exists = "overwrite"
  contents  = file("../../provider-config/eks/eks.tf")
}

inputs = {

  cluster_version = "1.21"
  cluster_name    = "my-cluster"

  vpc_id                          = dependency.vpc.outputs.vpc_id
  enable_irsa                     = true
  cluster_endpoint_private_access = true

  subnets = concat(dependency.vpc.outputs.private_subnets, dependency.vpc.outputs.public_subnets)

  worker_groups = [
    {
      name                 = "worker-group-1"
      instance_type        = "t2.medium"
      asg_desired_capacity = 2
      asg_max_size         = 2
      subnets              = dependency.vpc.outputs.private_subnets
      key_name             = dependency.key-pair.outputs.key_name
      asg_force_delete     = true
      enable_monitoring    = false
      # public_ip            = true
    }
  ]


  # node_groups = {
  #   "default-a-" = {
  #     desired_capacity   = 1
  #     ami_type           = "AL2_ARM_64"
  #     instance_types     = ["t4g.medium"]
  #     subnets            = [local.vpc.dependency.vpc.outputs.private_subnets[0]]
  #     kubelet_extra_args = "--max-pods=110"
  #     taints             = []
  #     k8s_labels = {
  #       size                            = "medium"
  #       network                         = "private"
  #       arch                            = "arm64"
  #       "topology.ebs.csi.aws.com/zone" = "${include.locals.merged.aws_region}a"
  #     }
  #   }
  # }

}
