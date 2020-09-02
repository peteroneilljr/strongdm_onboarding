terraform {
  required_version = ">= 0.12.26"
  required_providers {
    aws = ">= 3.4.0"
    sdm = ">= 1.0.4"
  }
}
provider aws {
  region     = local.region
  access_key = var.AWS_ACCESS_KEY_ID
  secret_key = var.AWS_SECRET_ACCESS_KEY
}
variable AWS_ACCESS_KEY_ID {}
variable AWS_SECRET_ACCESS_KEY {}
locals {
  region = "us-west-2"
}
provider sdm {
  api_access_key = var.SDM_API_ACCESS_KEY
  api_secret_key = var.SDM_API_SECRET_KEY
}
variable SDM_API_ACCESS_KEY {}
variable SDM_API_SECRET_KEY {}