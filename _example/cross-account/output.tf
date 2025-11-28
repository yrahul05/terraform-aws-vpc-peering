##########################################
# Cross-Account Peering Outputs
##########################################

output "peering_connection_id" {
  description = "VPC Peering Connection ID"
  value       = module.vpc-peering-cross-account.connection_id
}

output "accept_status" {
  value = module.vpc-peering-cross-account.accept_status
}

output "tags" {
  value = module.vpc-peering-cross-account.tags
}