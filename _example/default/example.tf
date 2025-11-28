provider "aws" {
  region = "us-west-1"
}

locals {
  name        = "same-region-vpc-peering"
  environment = "test"
}
module "vpc-peering-same-region" {
  source           = "./../.."
  environment      = local.environment
  name             = local.name
  label_order      = ["name"]
  managedby        = "Rahul Yadav"
  requestor_vpc_id = "vpc-01f92c927b598901c"
  acceptor_vpc_id  = "vpc-051a7918b7b01f7ab"
  # auto_accept = true (default)
  # accept_region not needed for same region
}