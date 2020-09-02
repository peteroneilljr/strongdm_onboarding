
#################
# EKS Cluster
#################

module "eks_cluster" {
  source = "terraform-aws-modules/eks/aws"
  # https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/12.2.0
  cluster_name    = var.prefix
  cluster_version = "1.16"
  subnets         = data.aws_subnet_ids.public.ids
  vpc_id          = data.aws_vpc.default.id

  # map_users = [{
  #   userarn  = aws_iam_user.eks_user.arn
  #   username = split("/", aws_iam_user.eks_user.arn)[length(split("/", aws_iam_user.eks_user.arn)) - 1]
  #   groups   = ["system:masters"]
  # }]

  map_roles = [{
    rolearn = aws_iam_role.eks_role.arn
    # username = element( split("/", aws_iam_role.eks_role.arn), -1)
    username = split("/", aws_iam_role.eks_role.arn)[length(split("/", aws_iam_role.eks_role.arn)) - 1]
    groups   = ["system:masters"]
  }]

  worker_groups = [
    {
      instance_type = "t3.small"
      asg_max_size  = 2
    }
  ]
  providers = {
    kubernetes = kubernetes.eks
  }
}
# output "eks_kubeconfig" {
#   value = module.eks_cluster.kubeconfig
# }

#################
# Kubernetes control of EKS
#################
data "aws_eks_cluster" "eks_data" {
  name = module.eks_cluster.cluster_id
}
data "aws_eks_cluster_auth" "eks_data" {
  name = module.eks_cluster.cluster_id
}
provider "kubernetes" {
  alias = "eks"

  version          = "~> 1.11"
  load_config_file = false

  host                   = data.aws_eks_cluster.eks_data.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_data.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.eks_data.token
}
#################
# IAM Access to cluster
#################
resource "aws_iam_user" "eks_user" {
  name = "eks_user"
  path = "/terraform/"
}
resource "aws_iam_access_key" "eks_user" {
  user = aws_iam_user.eks_user.name
}

resource "aws_iam_role" "eks_role" {
  name = "eks_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AssumeEKS",
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "${aws_iam_user.eks_user.arn}"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}
# #################
# # Register EKS with strongDM
# #################
resource "sdm_resource" "k8s_eks_data_eks" {
  amazon_eks {
    name         = "${var.prefix}-eks"
    cluster_name = data.aws_eks_cluster.eks_data.name

    endpoint = split("//", data.aws_eks_cluster.eks_data.endpoint)[1]
    region   = split(".", data.aws_eks_cluster.eks_data.endpoint)[2]

    certificate_authority  = base64decode(data.aws_eks_cluster.eks_data.certificate_authority.0.data)

    access_key        = aws_iam_access_key.eks_user.id
    secret_access_key = aws_iam_access_key.eks_user.secret

    role_arn = aws_iam_role.eks_role.arn
  }
}