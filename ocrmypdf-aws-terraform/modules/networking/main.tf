# Module for creating network infrastructure for OCRMyPDF

locals {
  create_vpc = var.vpc_id == null
  vpc_map = local.create_vpc ? { "vpc" = "create" } : {}
  public_subnet_map = local.create_vpc ? { for i, cidr in var.public_subnet_cidrs : "public-${i}" => {
    cidr = cidr
    az   = "${var.region}${["a", "b"][i]}"
  } } : {}
  private_subnet_map = local.create_vpc ? { for i, cidr in var.private_subnet_cidrs : "private-${i}" => {
    cidr = cidr
    az   = "${var.region}${["a", "b"][i]}"
  } } : {}
}

# Create VPC (if not provided existing vpc_id)
resource "aws_vpc" "main" {
  for_each = local.vpc_map
  
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    var.tags,
    {
      Name = "${var.prefix}-vpc-${var.environment}"
    }
  )
  
  lifecycle {
    # We can use a lifecycle block instead of prevent_destroy
    prevent_destroy = false
  }
}

# Private subnets
resource "aws_subnet" "private" {
  for_each = local.private_subnet_map
  
  vpc_id            = local.create_vpc ? aws_vpc.main["vpc"].id : var.vpc_id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = merge(
    var.tags,
    {
      Name = "${var.prefix}-${each.key}-subnet-${var.environment}"
    }
  )
}

# Public subnets
resource "aws_subnet" "public" {
  for_each = local.public_subnet_map
  
  vpc_id                  = local.create_vpc ? aws_vpc.main["vpc"].id : var.vpc_id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = merge(
    var.tags,
    {
      Name = "${var.prefix}-${each.key}-subnet-${var.environment}"
    }
  )
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  for_each = local.vpc_map
  
  vpc_id = aws_vpc.main[each.key].id

  tags = merge(
    var.tags,
    {
      Name = "${var.prefix}-igw-${var.environment}"
    }
  )
}

# Public route table
resource "aws_route_table" "public_rt" {
  for_each = local.vpc_map
  
  vpc_id = aws_vpc.main[each.key].id

  tags = merge(
    var.tags,
    {
      Name = "${var.prefix}-public-rt-${var.environment}"
    }
  )
}

# Public route through Internet Gateway
resource "aws_route" "public_igw_route" {
  for_each = local.vpc_map
  
  route_table_id         = aws_route_table.public_rt[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw[each.key].id
}

# Associate public route table with public subnets
resource "aws_route_table_association" "public" {
  for_each = local.public_subnet_map
  
  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public_rt["vpc"].id
}

# NAT Gateway and its components
# Elastic IP for NAT Gateway
resource "aws_eip" "nat_eip" {
  for_each = local.create_vpc && var.enable_nat_gateway ? local.vpc_map : {}
  
  tags = merge(
    var.tags,
    {
      Name = "${var.prefix}-nat-eip-${var.environment}"
    }
  )
}

# NAT Gateway
resource "aws_nat_gateway" "nat_gw" {
  for_each = local.create_vpc && var.enable_nat_gateway ? local.vpc_map : {}
  
  allocation_id = aws_eip.nat_eip[each.key].id
  subnet_id     = aws_subnet.public["public-0"].id

  tags = merge(
    var.tags,
    {
      Name = "${var.prefix}-nat-gw-${var.environment}"
    }
  )

  depends_on = [aws_internet_gateway.igw]
}

# Private route table
resource "aws_route_table" "private_rt" {
  for_each = local.vpc_map
  
  vpc_id = aws_vpc.main[each.key].id

  tags = merge(
    var.tags,
    {
      Name = "${var.prefix}-private-rt-${var.environment}"
    }
  )
}

# Private route through NAT Gateway, if enabled
resource "aws_route" "private_nat_route" {
  for_each = local.create_vpc && var.enable_nat_gateway ? local.vpc_map : {}
  
  route_table_id         = aws_route_table.private_rt[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gw[each.key].id
}

# Associate private route table with private subnets
resource "aws_route_table_association" "private" {
  for_each = local.private_subnet_map
  
  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private_rt["vpc"].id
}