variable "name" {
  type        = string
  default     = ""
  description = "Name of the peering connection"
}

variable "environment" {
  type        = string
  default     = ""
  description = "Environment (e.g., prod, dev, test)"
}

variable "label_order" {
  type        = list(any)
  default     = ["name", "environment"]
  description = "Label order, e.g. `name`,`Environment`."
}

variable "repository" {
  type        = string
  default     = "https://github.com/yrahul05/terraform-aws-vpc-peering"
  description = "Terraform current module repo"
}

variable "managedby" {
  type        = string
  default     = ""
  description = "Managed by"
}

variable "requestor_vpc_id" {
  type        = string
  description = "Requestor VPC ID"
}

variable "acceptor_vpc_id" {
  type        = string
  description = "Acceptor VPC ID"
}

variable "accept_region" {
  type        = string
  default     = ""
  description = "Acceptor region for cross-region peering"
}

variable "auto_accept" {
  type        = bool
  default     = true
  description = "Auto accept peering connection (true for same region, false for cross-region/cross-account)"
}

variable "peer_owner_id" {
  type        = string
  default     = ""
  description = "AWS account ID of acceptor for cross-account peering"
}

variable "acceptor_cidr_block" {
  type        = string
  default     = ""
  description = "Acceptor VPC CIDR block (required for cross-account)"
}

variable "enable_peering" {
  type        = bool
  default     = true
  description = "Enable VPC peering"
}

variable "acceptor_allow_remote_vpc_dns_resolution" {
  type        = bool
  default     = false
  description = "Allow DNS resolution from acceptor VPC"
}

variable "requestor_allow_remote_vpc_dns_resolution" {
  type        = bool
  default     = false
  description = "Allow DNS resolution from requestor VPC"
}