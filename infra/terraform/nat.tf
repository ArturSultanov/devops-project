resource "aws_eip" "eip" {
  domain = "vpc"

  tags = {
    Name = "${local.project_name}-nat-eip"
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public_subnet_1.id

  tags = {
    Name = "${local.project_name}-nat"
  }

  depends_on = [aws_subnet.public_subnet_1, aws_internet_gateway.igw]
}
