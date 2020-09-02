data "aws_caller_identity" "current" {}


module "es-cluster" {
  source = "git::https://github.com/egarbi/terraform-aws-es-cluster"

  name                           = var.prefix
  vpc_id                         = data.aws_vpc.default.id
  subnet_ids                     = [sort(data.aws_subnet_ids.public.ids)[0], sort(data.aws_subnet_ids.public.ids)[1]]
  itype                          = "t2.small.elasticsearch"
  icount                         = 2
  create_iam_service_linked_role = false
  zone_awareness                 = true
  ingress_allow_cidr_blocks      = [data.aws_vpc.default.cidr_block]
  access_policies                = <<CONFIG
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "es:*",
            "Principal": "*",
            "Effect": "Allow",
            "Resource": "arn:aws:es:${local.region}:${data.aws_caller_identity.current.account_id}:domain/${var.prefix}/*"
        }
    ]
}
CONFIG
}


resource "sdm_resource" "es_cluster" {
  amazon_es {
    name              = "${var.prefix}-es-cluster"
    endpoint          = module.es-cluster.es_endpoint
    region            = split(".", module.es-cluster.es_endpoint)[1]
    access_key        = null
    secret_access_key = null

    tags = var.default_tags
  }
}
output kibana_endpoint {
  value       = split("/", module.es-cluster.es_kibana_endpoint)[0]
  description = "description"
}

resource "sdm_resource" "kibana_endpoint" {
  http_no_auth {
    name             = "${var.prefix}-kibana"
    url              = "https://${split("/", module.es-cluster.es_kibana_endpoint)[0]}"
    default_path     = "/_plugin/kibana/"
    healthcheck_path = "/_plugin/kibana/"
    subdomain        = "kibana-dashboard"
    # headers_blacklist - (Optional)

    tags = var.default_tags
  }
}
