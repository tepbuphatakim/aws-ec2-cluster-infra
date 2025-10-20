resource "aws_vpc" "swarm_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "swarm-vpc"
    Environment = var.environment
  }
}

resource "aws_internet_gateway" "swarm_igw" {
  vpc_id = aws_vpc.swarm_vpc.id

  tags = {
    Name        = "swarm-igw"
    Environment = var.environment
  }
}

resource "aws_subnet" "public_subnets" {
  count                   = length(var.availability_zones)
  vpc_id                  = aws_vpc.swarm_vpc.id
  cidr_block             = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone      = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name        = "swarm-public-subnet-${count.index + 1}"
    Environment = var.environment
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.swarm_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.swarm_igw.id
  }

  tags = {
    Name        = "swarm-public-rt"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "public" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_rt.id
}
