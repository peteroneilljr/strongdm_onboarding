data "aws_vpc" "default" {
  default = true
}
data "aws_subnet_ids" "public" {
  vpc_id = data.aws_vpc.default.id
}
module "sdm" {
  source = "github.com/peteroneilljr/terraform_aws_strongdm_gateways"

  sdm_node_name = "${var.prefix}-gateway"

  deploy_vpc_id = data.aws_vpc.default.id

  gateway_subnet_ids = [
    sort(data.aws_subnet_ids.public.ids)[0],
    sort(data.aws_subnet_ids.public.ids)[1],
  ]
  dev_mode = true
}

