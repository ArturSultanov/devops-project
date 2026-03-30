resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Private subnets:
resource "aws_subnet" "private_subnet_1" {
  vpc_id = aws_vpc.vpc.id

  cidr_block        = var.private_subnet_1_cidr
  availability_zone = var.zone_1

  tags = {
    "Name"                                    = "private-subnet-${var.zone_1}"
    "kubernetes.io/role/internal-elb"         = "1"
    "kubernetes.io/cluster/${var.eks_name}" = "owned"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id = aws_vpc.vpc.id

  cidr_block        = var.private_subnet_2_cidr
  availability_zone = var.zone_2

  tags = {
    "Name"                                    = "private-subnet-${var.zone_2}"
    "kubernetes.io/role/internal-elb"         = "1"
    "kubernetes.io/cluster/${var.eks_name}" = "owned"
  }
}

# Public subnets:
resource "aws_subnet" "public_subnet_1" {
  vpc_id = aws_vpc.vpc.id

  cidr_block              = var.public_subnet_1_cidr
  availability_zone       = var.zone_1
  map_public_ip_on_launch = true

  tags = {
    "Name"                                    = "public-subnet-${var.zone_1}"
    "kubernetes.io/role/elb"                  = "1"
    "kubernetes.io/cluster/${var.eks_name}" = "owned"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id = aws_vpc.vpc.id

  cidr_block              = var.public_subnet_2_cidr
  availability_zone       = var.zone_2
  map_public_ip_on_launch = true

  tags = {
    "Name"                                    = "public-subnet-${var.zone_2}"
    "kubernetes.io/role/elb"                  = "1"
    "kubernetes.io/cluster/${var.eks_name}" = "owned"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}


resource "aws_eip" "eip" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-nat-eip"
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public_subnet_1.id

  tags = {
    Name = "${var.project_name}-nat"
  }
}


resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    # NAT
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "${var.project_name}-private-route-table"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    # IGW
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.project_name}-public-route-table"
  }
}

# Private subnets associations
resource "aws_route_table_association" "private_subnet_1" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_subnet_2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_route_table.id
}

# Public subnets associations
resource "aws_route_table_association" "public_subnet_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_subnet_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_route_table.id
}
