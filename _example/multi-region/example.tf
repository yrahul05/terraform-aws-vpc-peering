provider "aws" {
  region = "us-west-1"
}

module "vpc-peering-multi-region" {
  source           = "./../.."
  name             = "multi-region-vpc-peering"
  environment      = "test"
  label_order      = ["name"]
  managedby        = "Rahul Yadav"
  requestor_vpc_id = "vpc-01f92c927b598901c"
  acceptor_vpc_id  = "vpc-09af3b151e6280eb0"
  accept_region    = "us-east-1"
  auto_accept      = false
}