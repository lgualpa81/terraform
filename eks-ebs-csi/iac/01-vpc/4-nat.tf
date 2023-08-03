resource "aws_eip" "nat" {
  vpc   = true
  count = var.eks_node_group_single_az ? 1 : length(var.private_subnets_cidr)
  tags = {
    Name = "eip-${count.index + 1}-${var.environment}"
  }
}

resource "aws_nat_gateway" "nat" {
  count         = var.eks_node_group_single_az ? 1 : length(var.private_subnets_cidr)
  allocation_id = element(aws_eip.nat.*.id, count.index)
  subnet_id     = element(aws_subnet.public.*.id, count.index)

  depends_on = [aws_internet_gateway.igw]

  tags = {
    Name = "eks-nat_gtw-${count.index + 1}-${var.environment}"
  }

}
