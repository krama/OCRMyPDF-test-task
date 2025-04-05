# Module for creating network infrastructure for OCRMyPDF

# Create VPC (if not provided existing vpc_id)
resource "aws_vpc" "main" {
  count = var.create_vpc ? 1 : 0

  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    var.tags,
    {
      Name = "${var.prefix}-vpc-${var.environment}"
    }
  )
}

# Private subnets
resource "aws_subnet" "private_subnet_1" {
  count = var.create_vpc ? 1 : 0

  vpc_id            = aws_vpc.main[0].id
  cidr_block        = var.private_subnet_cidrs[0]
  availability_zone = "${var.region}a"

  tags = merge(
    var.tags,
    {
      Name = "${var.prefix}-private-subnet-1-${var.environment}"
    }
  )
}

resource "aws_subnet" "private_subnet_2" {
  count = var.create_vpc ? 1 : 0

  vpc_id            = aws_vpc.main[0].id
  cidr_block        = var.private_subnet_cidrs[1]
  availability_zone = "${var.region}b"

  tags = merge(
    var.tags,
    {
      Name = "${var.prefix}-private-subnet-2-${var.environment}"
    }
  )
}

# Public subnets
resource "aws_subnet" "public_subnet_1" {
  count = var.create_vpc ? 1 : 0

  vpc_id                  = aws_vpc.main[0].id
  cidr_block              = var.public_subnet_cidrs[0]
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true

  tags = merge(
    var.tags,
    {
      Name = "${var.prefix}-public-subnet-1-${var.environment}"
    }
  )
}

resource "aws_subnet" "public_subnet_2" {
  count = var.create_vpc ? 1 : 0

  vpc_id                  = aws_vpc.main[0].id
  cidr_block              = var.public_subnet_cidrs[1]
  availability_zone       = "${var.region}b"
  map_public_ip_on_launch = true

  tags = merge(
    var.tags,
    {
      Name = "${var.prefix}-public-subnet-2-${var.environment}"
    }
  )
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  count = var.create_vpc ? 1 : 0

  vpc_id = aws_vpc.main[0].id

  tags = merge(
    var.tags,
    {
      Name = "${var.prefix}-igw-${var.environment}"
    }
  )
}

# Public route table
resource "aws_route_table" "public_rt" {
  count = var.create_vpc ? 1 : 0

  vpc_id = aws_vpc.main[0].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw[0].id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.prefix}-public-rt-${var.environment}"
    }
  )
}

# Associate public route table with public subnets
resource "aws_route_table_association" "public_1" {
  count = var.create_vpc ? 1 : 0

  subnet_id      = aws_subnet.public_subnet_1[0].id
  route_table_id = aws_route_table.public_rt[0].id
}

resource "aws_route_table_association" "public_2" {
  count = var.create_vpc ? 1 : 0

  subnet_id      = aws_subnet.public_subnet_2[0].id
  route_table_id = aws_route_table.public_rt[0].id
}

# NAT Gateway and its components
# Elastic IP for NAT Gateway
resource "aws_eip" "nat_eip" {
  count = var.create_vpc && var.enable_nat_gateway ? 1 : 0
  
  tags = merge(
    var.tags,
    {
      Name = "${var.prefix}-nat-eip-${var.environment}"
    }
  )
}

# NAT Gateway
resource "aws_nat_gateway" "nat_gw" {
  count = var.create_vpc && var.enable_nat_gateway ? 1 : 0

  allocation_id = aws_eip.nat_eip[0].id
  subnet_id     = aws_subnet.public_subnet_1[0].id

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
  count = var.create_vpc ? 1 : 0

  vpc_id = aws_vpc.main[0].id

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.nat_gw[0].id
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.prefix}-private-rt-${var.environment}"
    }
  )
}

# Associate private route table with private subnets
resource "aws_route_table_association" "private_1" {
  count = var.create_vpc ? 1 : 0

  subnet_id      = aws_subnet.private_subnet_1[0].id
  route_table_id = aws_route_table.private_rt[0].id
}

resource "aws_route_table_association" "private_2" {
  count = var.create_vpc ? 1 : 0

  subnet_id      = aws_subnet.private_subnet_2[0].id
  route_table_id = aws_route_table.private_rt[0].id
}
