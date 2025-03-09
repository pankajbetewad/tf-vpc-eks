resource "aws_vpc" "eks-vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name                                         = "${var.cluster_name}-vpc"
    "pankaj.betewad/cluster/${var.cluster_name}" = "shared"
  }
}

resource "aws_subnet" "eks-private-subnets" {
  count                   = length(var.private_subnet_cidrs)
  vpc_id                  = aws_vpc.eks-vpc.id
  cidr_block              = var.private_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false
  tags = {
    Name                                         = "${var.cluster_name}-private-${count.index}"
    "pankaj.betewad/cluster/${var.cluster_name}" = "shared"
  }
}

resource "aws_subnet" "eks-public-subnets" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.eks-vpc.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name                                         = "${var.cluster_name}-public-${count.index}"
    "pankaj.betewad/cluster/${var.cluster_name}" = "shared"
  }
}

resource "aws_internet_gateway" "eks-igw" {
  vpc_id = aws_vpc.eks-vpc.id
  tags = {
    Name                                         = "${var.cluster_name}-igw"
    "pankaj.betewad/cluster/${var.cluster_name}" = "shared"
  }
}

resource "aws_route_table" "eks-public-route-table" {
  vpc_id = aws_vpc.eks-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eks-igw.id
  }
  tags = {
    Name                                         = "${var.cluster_name}-public-route-table"
    "pankaj.betewad/cluster/${var.cluster_name}" = "shared"
  }
}

resource "aws_route_table_association" "eks-public-subnet-route-table-association" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.eks-public-subnets[count.index].id
  route_table_id = aws_route_table.eks-public-route-table.id
}


resource "aws_route_table" "eks-private-route-table" {
  vpc_id = aws_vpc.eks-vpc.id
  count  = length(var.private_subnet_cidrs)
  tags = {
    Name                                         = "${var.cluster_name}-private-route-table"
    "pankaj.betewad/cluster/${var.cluster_name}" = "shared"
  }
}

resource "aws_route_table_association" "eks-private-subnet-route-table-association" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.eks-private-subnets[count.index].id
  route_table_id = aws_route_table.eks-private-route-table[count.index].id
}

resource "aws_eip" "eks-eip" {
  count  = length(var.public_subnet_cidrs)
  domain = "vpc"

  tags = {
    Name = "${var.cluster_name}-nat-${count.index + 1}"
  }
}
resource "aws_nat_gateway" "eks-nat-gateway" {
  count         = length(var.public_subnet_cidrs)
  allocation_id = aws_eip.eks-eip[count.index].id
  subnet_id     = aws_subnet.eks-public-subnets[count.index].id
  tags = {
    Name                                         = "${var.cluster_name}-nat-gateway-${count.index}"
    "pankaj.betewad/cluster/${var.cluster_name}" = "shared"
  }
}
