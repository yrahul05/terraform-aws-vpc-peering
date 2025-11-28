data "aws_region" "default" {}


locals {
  accept_region = var.accept_region != "" ? var.accept_region : data.aws_region.default.name

  acceptor_cidr_blocks = var.enable_peering ? (
    # Same region (auto_accept = true)
    var.auto_accept && length(data.aws_vpc.acceptor) > 0 ? data.aws_vpc.acceptor[0].cidr_block_associations[*].cidr_block : (
      # Multi-region same account (auto_accept = false, same owner)
      !var.auto_accept && var.peer_owner_id == "" && length(data.aws_vpc.acceptor_multi_region) > 0 ? [data.aws_vpc.acceptor_multi_region[0].cidr_block] : (
        # Cross-account (auto_accept = false, different owner) - use manual CIDR
        !var.auto_accept && var.peer_owner_id != "" ? [var.acceptor_cidr_block] : [var.acceptor_cidr_block]
      )
    )
  ) : []

  requestor_cidr_blocks = var.enable_peering && length(data.aws_vpc.requestor) > 0 ? data.aws_vpc.requestor[0].cidr_block_associations[*].cidr_block : []
}

module "labels" {
  source      = "git::https://github.com/yrahul05/terraform-aws-vpc-peering.git?ref=v1.0.0"
  name        = var.name
  environment = var.environment
  repository  = var.repository
  managedby   = var.managedby
  label_order = var.label_order
}

# Same region peering (auto_accept = true)
resource "aws_vpc_peering_connection" "default" {
  count = var.enable_peering && var.auto_accept ? 1 : 0

  vpc_id      = var.requestor_vpc_id
  peer_vpc_id = var.acceptor_vpc_id
  auto_accept = var.auto_accept
  accepter {
    allow_remote_vpc_dns_resolution = var.acceptor_allow_remote_vpc_dns_resolution
  }
  requester {
    allow_remote_vpc_dns_resolution = var.requestor_allow_remote_vpc_dns_resolution
  }
  tags = merge(
    module.labels.tags,
    {
      "Name" = module.labels.id
    }
  )
}

resource "aws_vpc_peering_connection" "region" {
  count = var.enable_peering && !var.auto_accept ? 1 : 0

  vpc_id        = var.requestor_vpc_id
  peer_vpc_id   = var.acceptor_vpc_id
  auto_accept   = false
  peer_region   = local.accept_region
  peer_owner_id = var.peer_owner_id != "" ? var.peer_owner_id : null

  tags = merge(
    module.labels.tags,
    {
      "Name" = format("%s-peering", module.labels.id)
    }
  )
}

# Acceptor for cross-region/cross-account
resource "aws_vpc_peering_connection_accepter" "peer" {
  count                     = var.enable_peering && !var.auto_accept ? 1 : 0
  provider                  = aws.peer
  vpc_peering_connection_id = aws_vpc_peering_connection.region[0].id
  auto_accept               = true

  tags = merge(
    module.labels.tags,
    {
      "Side" = "acceptor"
    }
  )
}

# Data sources
data "aws_vpc" "requestor" {
  count = var.enable_peering ? 1 : 0
  id    = var.requestor_vpc_id
}

# Same region acceptor VPC
data "aws_vpc" "acceptor" {
  provider = aws.peer
  count    = var.enable_peering && var.auto_accept ? 1 : 0
  id       = var.acceptor_vpc_id
}

data "aws_vpc" "acceptor_multi_region" {
  provider = aws.peer
  count    = var.enable_peering && !var.auto_accept && var.peer_owner_id == "" ? 1 : 0 # ✅ Only same account
  id       = var.acceptor_vpc_id
}

# Route tables
data "aws_route_tables" "requestor" {
  count  = var.enable_peering ? 1 : 0
  vpc_id = data.aws_vpc.requestor[0].id
}

data "aws_route_tables" "acceptor" {
  provider = aws.peer
  count    = var.enable_peering && var.auto_accept ? 1 : 0
  vpc_id   = var.auto_accept ? data.aws_vpc.acceptor[0].id : ""
}

# FIXED: Acceptor route tables - only for same account multi-region
data "aws_route_tables" "acceptor_multi_region" {
  provider = aws.peer
  count    = var.enable_peering && !var.auto_accept && var.peer_owner_id == "" ? 1 : 0
  vpc_id   = var.acceptor_vpc_id
}

# Routes for same region peering
resource "aws_route" "requestor_same_region" {
  count = var.enable_peering && var.auto_accept ? length(data.aws_route_tables.requestor[0].ids) * length(local.acceptor_cidr_blocks) : 0

  route_table_id            = element(data.aws_route_tables.requestor[0].ids, count.index % length(data.aws_route_tables.requestor[0].ids))
  destination_cidr_block    = element(local.acceptor_cidr_blocks, floor(count.index / length(data.aws_route_tables.requestor[0].ids)))
  vpc_peering_connection_id = aws_vpc_peering_connection.default[0].id
}

resource "aws_route" "acceptor_same_region" {
  count = var.enable_peering && var.auto_accept ? length(data.aws_route_tables.acceptor[0].ids) * length(local.requestor_cidr_blocks) : 0

  provider                  = aws.peer
  route_table_id            = element(data.aws_route_tables.acceptor[0].ids, count.index % length(data.aws_route_tables.acceptor[0].ids))
  destination_cidr_block    = element(local.requestor_cidr_blocks, floor(count.index / length(data.aws_route_tables.acceptor[0].ids)))
  vpc_peering_connection_id = aws_vpc_peering_connection.default[0].id
}

# Routes for cross-region/cross-account peering
resource "aws_route" "requestor_cross_region" {
  count = var.enable_peering && !var.auto_accept ? length(data.aws_route_tables.requestor[0].ids) * length(local.acceptor_cidr_blocks) : 0

  route_table_id            = element(data.aws_route_tables.requestor[0].ids, count.index % length(data.aws_route_tables.requestor[0].ids))
  destination_cidr_block    = element(local.acceptor_cidr_blocks, floor(count.index / length(data.aws_route_tables.requestor[0].ids)))
  vpc_peering_connection_id = aws_vpc_peering_connection.region[0].id
}

# FIXED: Acceptor routes - only create for same account multi-region
resource "aws_route" "acceptor_cross_region" {
  count = var.enable_peering && !var.auto_accept && var.peer_owner_id == "" ? length(data.aws_route_tables.acceptor_multi_region[0].ids) * length(local.requestor_cidr_blocks) : 0

  provider                  = aws.peer
  route_table_id            = element(data.aws_route_tables.acceptor_multi_region[0].ids, count.index % length(data.aws_route_tables.acceptor_multi_region[0].ids))
  destination_cidr_block    = element(local.requestor_cidr_blocks, floor(count.index / length(data.aws_route_tables.acceptor_multi_region[0].ids)))
  vpc_peering_connection_id = aws_vpc_peering_connection.region[0].id
}

# FIXED: Conditional provider - only create if accept_region is not empty
provider "aws" {
  alias  = "peer"
  region = local.accept_region
}
