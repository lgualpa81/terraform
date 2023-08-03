resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = element(var.private_subnets_cidr, count.index)
  availability_zone = element(var.availability_zones_private, count.index)
  count             = length(var.private_subnets_cidr)
  depends_on        = [aws_vpc.main]

  tags = {
    "Name"                                                         = "node-group-subnet-${count.index + 1}-${var.environment}"
    "kubernetes.io/role/internal-elb"                              = 1
    "kubernetes.io/cluster/${var.cluster_name}-${var.environment}" = "shared"
    "state"                                                        = "private"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = element(var.public_subnets_cidr, count.index)
  availability_zone       = element(var.availability_zones_public, count.index)
  count                   = length(var.public_subnets_cidr)
  map_public_ip_on_launch = true
  depends_on              = [aws_vpc.main]

  tags = {
    "Name"                                                         = "subnet-${count.index + 1}-${var.environment}"
    "kubernetes.io/cluster/${var.cluster_name}-${var.environment}" = "shared"
    "kubernetes.io/role/elb"                                       = 1
    "state"                                                        = "public"
  }
}

