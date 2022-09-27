terraform {
  source = "../../modules/cert-manager"
}


include "root" {
  path = find_in_parent_folders()
}

dependencies {
  paths = ["../eks", "../helm-charts"]
}


dependency "eks" {
  config_path = "../eks"

  mock_outputs = {
    cluster_endpoint                   = "localhost"
    cluster_certificate_authority_data = "dGVzdAo="
    cluster_id                         = "cluster"
    oidc_provider_arn                  = "temp"
    cluster_oidc_issuer_url            = "temp"
  }
}

generate "provider-kubectl" {
  path      = "provider-kubectl.tf"
  if_exists = "overwrite"
  contents  = <<EOF
provider "kubectl" {
    host                   = "${dependency.eks.outputs.cluster_endpoint}"
    cluster_ca_certificate = base64decode("${dependency.eks.outputs.cluster_certificate_authority_data}")
    load_config_file       = false
    exec {
      api_version = "client.authentication.k8s.io/v1alpha1"
      args        = ["token", "-i", "${dependency.eks.outputs.cluster_id}"]
      command     = "aws-iam-authenticator"
    }
}
EOF
}

generate "provider-helm" {
  path      = "provider-helm.tf"
  if_exists = "overwrite"
  contents  = <<EOF
provider "helm" {
  kubernetes {
    host                   = "${dependency.eks.outputs.cluster_endpoint}"
    cluster_ca_certificate = base64decode("${dependency.eks.outputs.cluster_certificate_authority_data}")
    exec {
      api_version = "client.authentication.k8s.io/v1alpha1"
      args        = ["eks", "get-token", "--cluster-name", "${dependency.eks.outputs.cluster_id}"]
      command     = "aws"
    }
  }
}
EOF
}


inputs = {


  provider_url   = dependency.eks.outputs.cluster_oidc_issuer_url
  hosted_zone_id = "Z07652822ZAAUUEX4TR78"
}
