
#########################################################################################################
## Create a VPC
#########################################################################################################
resource "aws_vpc" "vpc" {
  cidr_block           = "10.1.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.cluster_name}-vpc"
  }
}

#########################################################################################################
## Create Public & Private Subnet
#########################################################################################################
resource "aws_subnet" "public-subnet-a" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.1.1.0/24"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-0"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                               = "1"
    "kubernetes.io/role/alb"                               = "1"
  }
}

resource "aws_subnet" "public-subnet-c" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.1.2.0/24"
  availability_zone = "ap-northeast-2c"
  tags = {
    Name = "public-1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                               = "1"
    "kubernetes.io/role/alb"                               = "1"
  }
}

resource "aws_subnet" "private-subnet-a" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.1.3.0/24"
  availability_zone = "ap-northeast-2a"
  tags = {
    Name                                        = "private-0"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
  }
}

resource "aws_subnet" "private-subnet-c" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.1.4.0/24"
  availability_zone = "ap-northeast-2c"
  tags = {
    Name                                        = "private-1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
  }
}

#########################################################################################################
## Create Internet gateway & Nat gateway
#########################################################################################################
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.cluster_name}-igw"
  }
}

resource "aws_eip" "nat-eip" {
  domain = "vpc"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_nat_gateway" "nat-gateway" {
  subnet_id     = aws_subnet.public-subnet-a.id
  allocation_id = aws_eip.nat-eip.id
  tags = {
    Name = "${var.cluster_name}-nat-gateway"
  }
}

#########################################################################################################
## Create Route Table & Route
#########################################################################################################
resource "aws_route_table" "public-rtb" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "${var.cluster_name}-public-rtb"
  }
}


resource "aws_route_table_association" "public-rtb-assoc1" {
  route_table_id = aws_route_table.public-rtb.id
  subnet_id      = aws_subnet.public-subnet-a.id
}

resource "aws_route_table_association" "public-rtb-assoc2" {
  route_table_id = aws_route_table.public-rtb.id
  subnet_id      = aws_subnet.public-subnet-c.id
}


resource "aws_route_table" "private-rtb" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-gateway.id
  }
  tags = {
    Name = "${var.cluster_name}-private-rtb"
  }
}

resource "aws_route_table_association" "private-rtb-assoc1" {
  route_table_id = aws_route_table.private-rtb.id
  subnet_id      = aws_subnet.private-subnet-a.id
}

resource "aws_route_table_association" "private-rtb-assoc2" {
  route_table_id = aws_route_table.private-rtb.id
  subnet_id      = aws_subnet.private-subnet-c.id
}

#########################################################################################################
## Create Security Group
#########################################################################################################
resource "aws_security_group" "allow-ssh-sg" {
  name        = "allow-ssh"
  description = "allow ssh"
  vpc_id      = aws_vpc.vpc.id
}

resource "aws_security_group_rule" "allow-ssh" {
  from_port         = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.allow-ssh-sg.id
  to_port           = 22
  type              = "ingress"
  description       = "ssh"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group" "public-sg" {
  name        = "public-sg"
  description = "allow all ports"
  vpc_id      = aws_vpc.vpc.id
}

resource "aws_security_group_rule" "allow-all-ports" {
  from_port         = 0
  protocol          = "-1"
  security_group_id = aws_security_group.public-sg.id
  to_port           = 0
  type              = "ingress"
  description       = "all ports"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow-all-ports-egress" {
  from_port         = 0
  protocol          = "-1"
  security_group_id = aws_security_group.public-sg.id
  to_port           = 0
  type              = "egress"
  description       = "all ports"
  cidr_blocks       = ["0.0.0.0/0"]
}