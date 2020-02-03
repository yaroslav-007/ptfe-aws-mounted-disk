####Create PTFE VPC
resource "aws_vpc" "ptfe-vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "ptfe-vpc"
  }
}

# Create subnets for PTFE VPC

###Public Subnet
resource "aws_subnet" "ptfe-vpc-public-subnet" {
  vpc_id                  = aws_vpc.ptfe-vpc.id
  map_public_ip_on_launch = true
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "eu-west-2a"
  tags = {
    Name = "ptfe-vpc-public-subnet"
  }
}

###Private Subnet
resource "aws_subnet" "ptfe-vpc-private-subnet" {
  vpc_id                  = aws_vpc.ptfe-vpc.id
  map_public_ip_on_launch = false
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-2a"
  tags = {
    Name = "ptfe-vpc-private-subnet"
  }
}

# Create Internet GW for the Public Subnet within VPC
resource "aws_internet_gateway" "ptfe-vpc-internet-gw" {
  vpc_id = aws_vpc.ptfe-vpc.id

  tags = {
    Name = "ptfe-vpc-internet-gw"
  }

}
# Elastic IP 
resource "aws_eip" "ptfe-eip" {
  vpc = true
  tags = {
    Name = "ptfe-eip"
  }
}


# NAT GW for Private Subnets within VPC
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.ptfe-eip.id
  subnet_id     = aws_subnet.ptfe-vpc-public-subnet.id # The Subnet ID of the subnet in which to place the gateway. In this case it will be always the first subnet
  depends_on    = [aws_internet_gateway.ptfe-vpc-internet-gw]
  tags = {
    Name = "ptfe-nat-gateway"
  }
}


# Create second route table and route for Internet GW for the Public Subnet within VPC
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.ptfe-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ptfe-vpc-internet-gw.id
  }

  tags = {
    Name = "ptfe-public-route-table"
  }
}



# Assosiate second route table with the Public Subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.ptfe-vpc-public-subnet.id
  route_table_id = aws_route_table.public.id
}


# Create route to NAT GW for Private Subnets
resource "aws_route" "internet_access_throug_nat_gw" {
  route_table_id         = aws_vpc.ptfe-vpc.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gw.id
}

# Assosiate main route tables with Private subnets
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.ptfe-vpc-private-subnet.id
  route_table_id = aws_vpc.ptfe-vpc.main_route_table_id
}


# Create security group for VPC that allows ssh and icmp echo request/reply inbound traffic 
resource "aws_security_group" "vpc_ssh_icmp_echo_sg" {
  name        = "ssh_icmp_echo_enabled_sg"
  description = "Allow traffic needed for ssh and icmp echo request/reply"
  vpc_id      = aws_vpc.ptfe-vpc.id

  // Custom ICMP Rule - IPv4 Echo Reply
  ingress {
    from_port   = "0"
    to_port     = "-1"
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  // Custom ICMP Rule - IPv4 Echo Request
  ingress {
    from_port   = "8"
    to_port     = "-1"
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  // ssh
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
    from_port   = 8800
    to_port     = 8800
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  // all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "PTFE-security-group"
  }
}