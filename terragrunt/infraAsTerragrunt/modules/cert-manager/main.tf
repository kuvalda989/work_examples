
data "aws_region" "current" {}

variable "iam_policy_name" {
  description = "Create IAM policy with this name"
  type        = string
  default     = "cert_manager_policy"
}

variable "role_name" {
  description = "Create IAM role with this name"
  type        = string
  default     = "cert_manager_role"
}

variable "hosted_zone_id" {
  description = "id of DNS hosted zone"
  default     = "*"
}

variable "provider_url" {
  description = "openid provider url"
  default     = ""
}

variable "namespace" {
  description = "cert-manager namespace"
  default     = "cert-manager"
}

variable "aws_region_route53" {
  description = "route53 region"
  default     = ""
}

resource "aws_iam_policy" "cert_manager_policy" {
  name        = var.iam_policy_name
  path        = "/"
  description = "Policy, which allows CertManager to create Route53 records"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : "route53:GetChange",
        "Resource" : "arn:aws:route53:::change/*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "route53:ChangeResourceRecordSets",
          "route53:ListResourceRecordSets"
        ],
        "Resource" : "arn:aws:route53:::hostedzone/${var.hosted_zone_id}"
      },
    ]
    }
  )
}


module "cert_manager_irsa" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "3.6.0"
  create_role                   = true
  role_name                     = var.role_name
  provider_url                  = var.provider_url
  role_policy_arns              = [aws_iam_policy.cert_manager_policy.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:${var.namespace}:cert-manager"]
}


resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  namespace        = var.namespace
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = "v1.6.0"
  create_namespace = true
  depends_on = [
    aws_iam_policy.cert_manager_policy,
    module.cert_manager_irsa
  ]

  set {
    name  = "installCRDs"
    value = "true"
  }

  set {
    name  = "securityContext.enabled"
    value = "true"
  }

  set {
    name  = "securityContext.fsGroup"
    value = 1001
  }
  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.cert_manager_irsa.this_iam_role_arn
  }
}


resource "kubectl_manifest" "letsencrypt-stage-manifest" {
  depends_on = [
    helm_release.cert_manager,
  ]
  yaml_body = <<YAML
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-stage
spec:
  acme:
    email: kuvalda989@mail.ru
    privateKeySecretRef:
      name: letsencrypt-stage
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    solvers:
      - dns01:
          route53:
            region: %{if var.aws_region_route53 != ""}${var.aws_region_route53}%{else}${data.aws_region.current.name}%{endif}
            hostedZoneID: ${var.hosted_zone_id}
YAML
}

output "cert_manager_irsa_role_arn" {
  value = module.cert_manager_irsa.this_iam_role_arn
}
