# ━━━ Output variables of the networking module ━━━━━━━━━━━━━━━━━━━━━━━

output "vpc_id" {
  description = "ID of the created or existing VPC"
  value       = local.create_vpc ? aws_vpc.main["vpc"].id : var.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = local.create_vpc ? var.vpc_cidr : null
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = local.create_vpc ? [for s in aws_subnet.private : s.id] : []
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = local.create_vpc ? [for s in aws_subnet.public : s.id] : []
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = local.create_vpc && var.enable_nat_gateway ? aws_nat_gateway.nat_gw["vpc"].id : null
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = local.create_vpc ? aws_internet_gateway.igw["vpc"].id : null
}

output "public_route_table_id" {
  description = "ID of the route table for public subnets"
  value       = local.create_vpc ? aws_route_table.public_rt["vpc"].id : null
}

output "private_route_table_id" {
  description = "ID of the route table for private subnets"
  value       = local.create_vpc ? aws_route_table.private_rt["vpc"].id : null
}