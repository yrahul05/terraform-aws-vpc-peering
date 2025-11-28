provider "aws" {
  region = "us-west-1"
}

module "vpc-peering-cross-account" {
  source              = "./../.."
  name                = "cross-account"
  environment         = "test"
  label_order         = ["name"]
  managedby           = "Rahul Yadav"
  requestor_vpc_id    = "vpc-01f92c927b598901c"
  acceptor_vpc_id     = "vpc-008079d75cc82354e"
  auto_accept         = false
  accept_region       = "us-east-1"
  peer_owner_id       = "618122462084"
  acceptor_cidr_block = "10.0.0.0/24"
}