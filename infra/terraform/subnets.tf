# Private subnets:
resource "aws_subnet" "private_subnet_1" {
  vpc_id = aws_vpc.vpc.id

  cidr_block        = "10.0.0.0/24"
  availability_zone = local.zone_1

  tags = {
    "Name"                                    = "private-subnet-${local.zone_1}"
    "kubernetes.io/role/internal-elb"         = "1"
    "kubernetes.io/cluster/${local.eks_name}" = "owned"
  }

  depends_on = [aws_vpc.vpc]
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id = aws_vpc.vpc.id

  cidr_block        = "10.0.1.0/24"
  availability_zone = local.zone_2

  tags = {
    "Name"                                    = "private-subnet-${local.zone_2}"
    "kubernetes.io/role/internal-elb"         = "1"
    "kubernetes.io/cluster/${local.eks_name}" = "owned"
  }

  depends_on = [aws_vpc.vpc]
}

# Public subnets:
resource "aws_subnet" "public_subnet_1" {
  vpc_id = aws_vpc.vpc.id

  cidr_block        = "10.0.2.0/24"
  availability_zone = local.zone_1
  map_public_ip_on_launch = true

  tags = {
    "Name"                                    = "public-subnet-${local.zone_1}"
    "kubernetes.io/role/elb"                  = "1"
    "kubernetes.io/cluster/${local.eks_name}" = "owned"
  }

  depends_on = [aws_vpc.vpc]
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id = aws_vpc.vpc.id

  cidr_block        = "10.0.3.0/24"
  availability_zone = local.zone_2
  map_public_ip_on_launch = true

  tags = {
    "Name"                                    = "public-subnet-${local.zone_2}"
    "kubernetes.io/role/elb"                  = "1"
    "kubernetes.io/cluster/${local.eks_name}" = "owned"
  }

  depends_on = [aws_vpc.vpc]
}
