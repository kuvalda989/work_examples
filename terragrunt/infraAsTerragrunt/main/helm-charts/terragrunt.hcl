terraform {
  source = "../../modules/helm-charts/"
}

include "root" {
  path = find_in_parent_folders()
}

dependencies {
  paths = ["../eks"]
}


dependency "eks" {
  config_path = "../eks"

  mock_outputs = {
    cluster_endpoint                   = "localhost"
    cluster_certificate_authority_data = "dGVzdAo="
    cluster_id                         = "cluster"
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
  charts = [{
    name       = "cilium"
    repository = "https://helm.cilium.io/"
    chart      = "cilium"
    version    = "1.9.0"
    namespace  = "kube-system"
    set = [{
      name  = "egressMasqueradeInterfaces"
      value = "eth0"
      }, {
      name  = "nodeinit.enabled"
      value = "true"
      }, {
      name  = "eni"
      value = "true"
    },{
      name = "tunnel"
      value = "disabled"
    },{
      name = "ipam.mode"
      value = "eni"
    }]
    }, {
    name             = "ingress-nginx"
    repository       = "https://kubernetes.github.io/ingress-nginx"
    chart            = "ingress-nginx"
    version          = "4.0.6"
    namespace        = "ingress-nginx"
    create_namespace = "true"
  }, {
    name = "prometheus"
    repository = "https://prometheus-community.github.io/helm-charts"
    chart = "prometheus-operator"
    version = "9.3.2"
    namespace = "monitoring"
    create_namespace = "true"
    values_file      = "./prometheus-operator-values.yaml"
  },{
    name = "argocd"
    repository = "https://argoproj.github.io/argo-helm"
    chart = "argo-cd"
    version = "4.6.4"
    namespace = "argocd"
    create_namespace = "true"
    values_file      = "./argocd-values.yaml"
  }]
}
