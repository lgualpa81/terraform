resource "aws_route_table" "internet-route" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = var.cidr_block-internet_gw
    gateway_id = aws_internet_gateway.igw.id
  }
  depends_on = [aws_vpc.main]
  tags = {
    Name  = "eks-public_route_table-${var.environment}"
    state = "public"
  }
}

resource "aws_route_table" "nat-route" {
  vpc_id = aws_vpc.main.id
  count  = length(var.private_subnets_cidr)

  route {
    cidr_block     = var.cidr_block-nat_gw
    nat_gateway_id = element(aws_nat_gateway.nat.*.id, count.index)
  }
  depends_on = [aws_vpc.main]
  tags = {
    state = "public"
    Name = "eks-nat_route_table-${count.index + 1}-${var.environment}"
  }
}



resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets_cidr)
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.internet-route.id

  depends_on = [aws_route_table.internet-route,
    aws_subnet.public
  ]
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnets_cidr)
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.nat-route.*.id, count.index)
  depends_on = [aws_route_table.nat-route,
    aws_subnet.private
  ]
}
