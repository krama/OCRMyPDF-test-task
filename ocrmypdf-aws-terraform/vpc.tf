locals {
  create_vpc  = var.vpc_id == null
  vpc_id      = local.create_vpc ? aws_vpc.main["vpc"].id : var.vpc_id
  
  subnet_map = {
    "private_1" = {
      cidr_block        = "10.0.1.0/24"
      availability_zone = "${var.region}a"
      is_public         = false
    },
    "private_2" = {
      cidr_block        = "10.0.2.0/24"
      availability_zone = "${var.region}b" 
      is_public         = false
    },
    "public_1"  = {
      cidr_block        = "10.0.3.0/24"
      availability_zone = "${var.region}a"
      is_public         = true
    },
    "public_2"  = {
      cidr_block        = "10.0.4.0/24"
      availability_zone = "${var.region}b"
      is_public         = true
    }
  }
  
  private_subnets = { for k, v in local.subnet_map : k => v if !v.is_public }
  public_subnets  = { for k, v in local.subnet_map : k => v if v.is_public }
}

resource "aws_vpc" "main" {
  for_each = local.create_vpc ? { "vpc" = true } : {}

  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.prefix}-vpc-${var.environment}"
  }
}

resource "aws_subnet" "subnets" {
  for_each = local.create_vpc ? local.subnet_map : {}

  vpc_id                  = aws_vpc.main["vpc"].id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = each.value.is_public

  tags = {
    Name = "${var.prefix}-${each.key}-subnet-${var.environment}"
  }
  
  depends_on = [aws_vpc.main]
}

resource "aws_internet_gateway" "igw" {
  for_each = local.create_vpc ? { "igw" = true } : {}

  vpc_id = aws_vpc.main["vpc"].id

  tags = {
    Name = "${var.prefix}-igw-${var.environment}"
  }
  
  depends_on = [aws_vpc.main]
}

resource "aws_route_table" "public_rt" {
  for_each = local.create_vpc ? { "public" = true } : {}

  vpc_id = aws_vpc.main["vpc"].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw["igw"].id
  }

  tags = {
    Name = "${var.prefix}-public-rt-${var.environment}"
  }
  
  depends_on = [aws_vpc.main, aws_internet_gateway.igw]
}

resource "aws_route_table_association" "public" {
  for_each = local.create_vpc ? local.public_subnets : {}

  subnet_id      = aws_subnet.subnets[each.key].id
  route_table_id = aws_route_table.public_rt["public"].id
  
  depends_on = [aws_subnet.subnets, aws_route_table.public_rt]
}

resource "aws_eip" "nat_eip" {
  for_each = local.create_vpc ? { "nat" = true } : {}

  tags = {
    Name = "${var.prefix}-nat-eip-${var.environment}"
  }
  
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "nat_gw" {
  for_each = local.create_vpc ? { "nat" = true } : {}

  allocation_id = aws_eip.nat_eip["nat"].id
  subnet_id     = aws_subnet.subnets["public_1"].id

  tags = {
    Name = "${var.prefix}-nat-gw-${var.environment}"
  }

  depends_on = [aws_internet_gateway.igw, aws_subnet.subnets, aws_eip.nat_eip]
}

resource "aws_route_table" "private_rt" {
  for_each = local.create_vpc ? { "private" = true } : {}

  vpc_id = aws_vpc.main["vpc"].id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw["nat"].id
  }

  tags = {
    Name = "${var.prefix}-private-rt-${var.environment}"
  }
  
  depends_on = [aws_vpc.main, aws_nat_gateway.nat_gw]
}

resource "aws_route_table_association" "private" {
  for_each = local.create_vpc ? local.private_subnets : {}

  subnet_id      = aws_subnet.subnets[each.key].id
  route_table_id = aws_route_table.private_rt["private"].id
  
  depends_on = [aws_subnet.subnets, aws_route_table.private_rt]
}