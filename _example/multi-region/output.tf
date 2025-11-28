output "accept_status" {
  value       = module.vpc-peering-multi-region.accept_status
  description = "The status of the VPC peering connection request."
}

output "tags" {
  value       = module.vpc-peering-multi-region.tags
  description = "A mapping of tags to assign to the VPC Peering."
}

output "connection_id" {
  value = module.vpc-peering-multi-region.connection_id
}