terraform {
  source = "tfr:///lablabs/eks-external-dns/aws?version=0.8.1"
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


  cluster_identity_oidc_issuer     = dependency.eks.outputs.cluster_oidc_issuer_url
  cluster_identity_oidc_issuer_arn = dependency.eks.outputs.oidc_provider_arn
  cluster_name                     = dependency.eks.outputs.cluster_id
  policy_allowed_zone_ids          = ["Z07652822ZAAUUEX4TR78"]
}
