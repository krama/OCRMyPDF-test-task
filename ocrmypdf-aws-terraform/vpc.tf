resource "aws_vpc" "main" {
  count = var.vpc_id == null ? 1 : 0
  
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  
  tags = {
    Name = "${var.prefix}-vpc-${var.environment}"
  }
}

resource "aws_subnet" "private_subnet_1" {
  count = var.vpc_id == null ? 1 : 0
  
  vpc_id            = aws_vpc.main[0].id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.region}a"
  
  tags = {
    Name = "${var.prefix}-private-subnet-1-${var.environment}"
  }
}

resource "aws_subnet" "private_subnet_2" {
  count = var.vpc_id == null ? 1 : 0
  
  vpc_id            = aws_vpc.main[0].id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.region}b"
  
  tags = {
    Name = "${var.prefix}-private-subnet-2-${var.environment}"
  }
}

resource "aws_subnet" "public_subnet_1" {
  count = var.vpc_id == null ? 1 : 0
  
  vpc_id                  = aws_vpc.main[0].id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true
  
  tags = {
    Name = "${var.prefix}-public-subnet-1-${var.environment}"
  }
}

resource "aws_subnet" "public_subnet_2" {
  count = var.vpc_id == null ? 1 : 0
  
  vpc_id                  = aws_vpc.main[0].id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "${var.region}b"
  map_public_ip_on_launch = true
  
  tags = {
    Name = "${var.prefix}-public-subnet-2-${var.environment}"
  }
}

# Интернет-шлюз для публичных подсетей
resource "aws_internet_gateway" "igw" {
  count = var.vpc_id == null ? 1 : 0
  
  vpc_id = aws_vpc.main[0].id
  
  tags = {
    Name = "${var.prefix}-igw-${var.environment}"
  }
}

# Таблица маршрутизации для публичных подсетей
resource "aws_route_table" "public_rt" {
  count = var.vpc_id == null ? 1 : 0
  
  vpc_id = aws_vpc.main[0].id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw[0].id
  }
  
  tags = {
    Name = "${var.prefix}-public-rt-${var.environment}"
  }
}

# Ассоциация таблицы маршрутизации с публичными подсетями
resource "aws_route_table_association" "public_1" {
  count = var.vpc_id == null ? 1 : 0
  
  subnet_id      = aws_subnet.public_subnet_1[0].id
  route_table_id = aws_route_table.public_rt[0].id
}

resource "aws_route_table_association" "public_2" {
  count = var.vpc_id == null ? 1 : 0
  
  subnet_id      = aws_subnet.public_subnet_2[0].id
  route_table_id = aws_route_table.public_rt[0].id
}

# NAT Gateway для приватных подсетей
resource "aws_eip" "nat_eip" {
  count = var.vpc_id == null ? 1 : 0
  domain = "vpc"
  
  tags = {
    Name = "${var.prefix}-nat-eip-${var.environment}"
  }
}

resource "aws_nat_gateway" "nat_gw" {
  count = var.vpc_id == null ? 1 : 0
  
  allocation_id = aws_eip.nat_eip[0].id
  subnet_id     = aws_subnet.public_subnet_1[0].id
  
  tags = {
    Name = "${var.prefix}-nat-gw-${var.environment}"
  }
  
  # Зависимость от создания Internet Gateway
  depends_on = [aws_internet_gateway.igw]
}

# Таблица маршрутизации для приватных подсетей
resource "aws_route_table" "private_rt" {
  count = var.vpc_id == null ? 1 : 0
  
  vpc_id = aws_vpc.main[0].id
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw[0].id
  }
  
  tags = {
    Name = "${var.prefix}-private-rt-${var.environment}"
  }
}

# Ассоциация таблицы маршрутизации с приватными подсетями
resource "aws_route_table_association" "private_1" {
  count = var.vpc_id == null ? 1 : 0
  
  subnet_id      = aws_subnet.private_subnet_1[0].id
  route_table_id = aws_route_table.private_rt[0].id
}

resource "aws_route_table_association" "private_2" {
  count = var.vpc_id == null ? 1 : 0
  
  subnet_id      = aws_subnet.private_subnet_2[0].id
  route_table_id = aws_route_table.private_rt[0].id
}