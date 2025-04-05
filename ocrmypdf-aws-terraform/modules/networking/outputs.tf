# ━━━ Output variables of the networking module ━━━━━━━━━━━━━━━━━━━━━━━

output "vpc_id" {
  description = "ID of the created or existing VPC"
  value       = var.create_vpc ? aws_vpc.main[0].id : var.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = var.create_vpc ? aws_vpc.main[0].cidr_block : null
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value = var.create_vpc ? [
    aws_subnet.private_subnet_1[0].id,
    aws_subnet.private_subnet_2[0].id
  ] : []
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value = var.create_vpc ? [
    aws_subnet.public_subnet_1[0].id,
    aws_subnet.public_subnet_2[0].id
  ] : []
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = var.create_vpc && var.enable_nat_gateway ? aws_nat_gateway.nat_gw[0].id : null
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = var.create_vpc ? aws_internet_gateway.igw[0].id : null
}

output "public_route_table_id" {
  description = "ID of the route table for public subnets"
  value       = var.create_vpc ? aws_route_table.public_rt[0].id : null
}

output "private_route_table_id" {
  description = "ID of the route table for private subnets"
  value       = var.create_vpc ? aws_route_table.private_rt[0].id : null
}
