resource "aws_internet_gateway" "igw" {
  vpc_id     = aws_vpc.main.id
  depends_on = [aws_vpc.main]

  tags = {
    Name = "eks-igw-${var.environment}"
  }
}
