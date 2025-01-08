######################################################################################################################
# Kubernetes
######################################################################################################################
data "aws_eks_cluster" "cluster" {
   name = module.eks.cluster_name
   depends_on = [module.eks.cluster_name]
}

data "aws_eks_cluster_auth" "cluster" {
   name = module.eks.cluster_name
   depends_on = [module.eks.cluster_name]
}

provider "kubernetes" {
  alias                  = "cwave-eks"
  host                   = data.aws_eks_cluster.cluster.endpoint
  # token                  = data.aws_eks_cluster_auth.cluster.token
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      var.cluster_name,
      "--region",
      var.aws_region,
      "--profile",
      var.terraform_aws_profile
    ]
  }
}

######################################################################################################################
# 헬름차트
# 쿠버네티스 클러스터 추가 될때마다 alias 를 변경해서 추가해주기
######################################################################################################################
provider "helm" {
  alias = "cwave-eks-helm"

  kubernetes {
    host                   = module.eks.cluster_endpoint
    token                  = data.aws_eks_cluster_auth.eks_cluster_auth.token
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks",
        "get-token",
        "--cluster-name",
        module.eks.cluster_name,
        "--region",
        var.aws_region,
        "--profile",
        var.terraform_aws_profile
      ]
    }
  }
}

########################################################################################
#   Helm release : alb
########################################################################################
resource "helm_release" "eks_common_alb" {
  provider   = helm.cwave-eks-helm
  name       = "aws-load-balancer-controller"
  chart      = "aws-load-balancer-controller"
  version    = "1.6.2"
  repository = "https://aws.github.io/eks-charts"
  namespace  = "kube-system"

  dynamic "set" {
    for_each = {
      "clusterName"                                               = var.cluster_name
      "serviceAccount.create"                                     = "true"
      "serviceAccount.name"                                       = "aws-load-balancer-controller"
      "region"                                                    = var.aws_region
      "vpcId"                                                     = aws_vpc.vpc.id
      "image.repository"                                          = "602401143452.dkr.ecr.${var.aws_region}.amazonaws.com/amazon/aws-load-balancer-controller"
      "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn" = module.lb_controller_role.iam_role_arn
    }

    content {
      name  = set.key
      value = set.value
    }
  }
  depends_on = [
    module.eks,
    module.lb_controller_role
  ]
}