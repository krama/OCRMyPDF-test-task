#  ╦  ╦╔═╗╔═╗  ╔═╗╦═╗╔═╗╔═╗╔╦╗╦╔═╗╔╗╔
#  ╚╗╔╝╠═╝║    ║  ╠╦╝║╣ ╠═╣ ║ ║║ ║║║║
#   ╚╝ ╩  ╚═╝  ╚═╝╩╚═╚═╝╩ ╩ ╩ ╩╚═╝╝╚╝

# Create a new VPC if no external VPC ID is provided
resource "aws_vpc" "main" {
  count = var.vpc_id == null ? 1 : 0

  cidr_block           = "10.0.0.0/16"                     # Main CIDR block for the VPC
  enable_dns_support   = true                              # Enable DNS support
  enable_dns_hostnames = true                              # Enable DNS hostnames

  tags = {
    Name = "${var.prefix}-vpc-${var.environment}"         # Tag: VPC name
  }
}

#  ╔═╗╦ ╦╔╗ ╔╗╔╔═╗╔╦╗╔═╗  ╔═╗╦═╗╦╦  ╦╔═╗╔╦╗╔═╗
#  ╚═╗║ ║╠╩╗║║║║╣  ║ ╚═╗  ╠═╝╠╦╝║╚╗╔╝╠═╣ ║ ║╣ 
#  ╚═╝╚═╝╚═╝╝╚╝╚═╝ ╩ ╚═╝  ╩  ╩╚═╩ ╚╝ ╩ ╩ ╩ ╚═╝

# Create private subnet 1
resource "aws_subnet" "private_subnet_1" {
  count = var.vpc_id == null ? 1 : 0

  vpc_id            = aws_vpc.main[0].id                 # Reference to the main VPC
  cidr_block        = "10.0.1.0/24"                      # CIDR block for private subnet 1
  availability_zone = "${var.region}a"                   # Availability zone

  tags = {
    Name = "${var.prefix}-private-subnet-1-${var.environment}"  # Tag: Private subnet 1
  }
}

# Create private subnet 2
resource "aws_subnet" "private_subnet_2" {
  count = var.vpc_id == null ? 1 : 0

  vpc_id            = aws_vpc.main[0].id                 # Reference to the main VPC
  cidr_block        = "10.0.2.0/24"                      # CIDR block for private subnet 2
  availability_zone = "${var.region}b"                   # Availability zone

  tags = {
    Name = "${var.prefix}-private-subnet-2-${var.environment}"  # Tag: Private subnet 2
  }
}

#  ╔═╗╦ ╦╔╗ ╔╗╔╔═╗╔╦╗╔═╗  ╔═╗╦ ╦╔╗ ╦  ╦╔═╗
#  ╚═╗║ ║╠╩╗║║║║╣  ║ ╚═╗  ╠═╝║ ║╠╩╗║  ║║  
#  ╚═╝╚═╝╚═╝╝╚╝╚═╝ ╩ ╚═╝  ╩  ╚═╝╚═╝╩═╝╩╚═╝

# Create public subnet 1
resource "aws_subnet" "public_subnet_1" {
  count = var.vpc_id == null ? 1 : 0

  vpc_id                  = aws_vpc.main[0].id            # Reference to the main VPC
  cidr_block              = "10.0.3.0/24"                 # CIDR block for public subnet 1
  availability_zone       = "${var.region}a"              # Availability zone
  map_public_ip_on_launch = true                        # Enable automatic public IP assignment

  tags = {
    Name = "${var.prefix}-public-subnet-1-${var.environment}"  # Tag: Public subnet 1
  }
}

# Create public subnet 2
resource "aws_subnet" "public_subnet_2" {
  count = var.vpc_id == null ? 1 : 0

  vpc_id                  = aws_vpc.main[0].id            # Reference to the main VPC
  cidr_block              = "10.0.4.0/24"                 # CIDR block for public subnet 2
  availability_zone       = "${var.region}b"              # Availability zone
  map_public_ip_on_launch = true                        # Enable automatic public IP assignment

  tags = {
    Name = "${var.prefix}-public-subnet-2-${var.environment}"  # Tag: Public subnet 2
  }
}

#  ╦╔═╗  ╔═╗╦ ╦╔╗ ╦  ╦╔═╗
#  ║║ ╦  ╠═╝║ ║╠╩╗║  ║║  
#  ╩╚═╝  ╩  ╚═╝╚═╝╩═╝╩╚═╝

# Create an Internet Gateway for public subnets
resource "aws_internet_gateway" "igw" {
  count = var.vpc_id == null ? 1 : 0

  vpc_id = aws_vpc.main[0].id                             # Attach to the main VPC

  tags = {
    Name = "${var.prefix}-igw-${var.environment}"         # Tag: Internet Gateway
  }
}

#  ╦═╗╔═╗╦ ╦╔╦╗╔═╗
#  ╠╦╝║ ║║ ║ ║ ║╣ 
#  ╩╚═╚═╝╚═╝ ╩ ╚═╝

# Create a route table for public subnets
resource "aws_route_table" "public_rt" {
  count = var.vpc_id == null ? 1 : 0

  vpc_id = aws_vpc.main[0].id                             # Reference to the main VPC

  route {
    cidr_block = "0.0.0.0/0"                              # Route all traffic to the internet
    gateway_id = aws_internet_gateway.igw[0].id           # Use the Internet Gateway
  }

  tags = {
    Name = "${var.prefix}-public-rt-${var.environment}"   # Tag: Public route table
  }
}

# Associate the public route table with public subnet 1
resource "aws_route_table_association" "public_1" {
  count = var.vpc_id == null ? 1 : 0

  subnet_id      = aws_subnet.public_subnet_1[0].id        # Public subnet 1 ID
  route_table_id = aws_route_table.public_rt[0].id           # Public route table ID
}

# Associate the public route table with public subnet 2
resource "aws_route_table_association" "public_2" {
  count = var.vpc_id == null ? 1 : 0

  subnet_id      = aws_subnet.public_subnet_2[0].id        # Public subnet 2 ID
  route_table_id = aws_route_table.public_rt[0].id           # Public route table ID
}

#  ╔╗╔╔═╗╔╦╗
#  ║║║╠═╣ ║ 
#  ╝╚╝╩ ╩ ╩ 

# Allocate an Elastic IP for the NAT Gateway
resource "aws_eip" "nat_eip" {
  count  = var.vpc_id == null ? 1 : 0
  tags = {
    Name = "${var.prefix}-nat-eip-${var.environment}"    # Tag: NAT Elastic IP
  }
}

# Create a NAT Gateway for private subnets
resource "aws_nat_gateway" "nat_gw" {
  count = var.vpc_id == null ? 1 : 0

  allocation_id = aws_eip.nat_eip[0].id                  # Reference to the allocated Elastic IP
  subnet_id     = aws_subnet.public_subnet_1[0].id         # Place NAT Gateway in public subnet 1

  tags = {
    Name = "${var.prefix}-nat-gw-${var.environment}"       # Tag: NAT Gateway
  }

  depends_on = [aws_internet_gateway.igw]                # Depends on the Internet Gateway creation
}

# Create a route table for private subnets that routes through the NAT Gateway
resource "aws_route_table" "private_rt" {
  count = var.vpc_id == null ? 1 : 0

  vpc_id = aws_vpc.main[0].id                             # Reference to the main VPC

  route {
    cidr_block     = "0.0.0.0/0"                          # Route all traffic to the internet
    nat_gateway_id = aws_nat_gateway.nat_gw[0].id           # Use the NAT Gateway for outbound traffic
  }

  tags = {
    Name = "${var.prefix}-private-rt-${var.environment}"   # Tag: Private route table
  }
}

# Associate the private route table with private subnet 1
resource "aws_route_table_association" "private_1" {
  count = var.vpc_id == null ? 1 : 0

  subnet_id      = aws_subnet.private_subnet_1[0].id       # Private subnet 1 ID
  route_table_id = aws_route_table.private_rt[0].id          # Private route table ID
}

# Associate the private route table with private subnet 2
resource "aws_route_table_association" "private_2" {
  count = var.vpc_id == null ? 1 : 0

  subnet_id      = aws_subnet.private_subnet_2[0].id       # Private subnet 2 ID
  route_table_id = aws_route_table.private_rt[0].id          # Private route table ID
}
