#Private Network where cloud resources are deployed
resource "aws_vpc" "dbt_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "dbt_vpc"
  }
}

#Allows VPC to communicate with the internet
# Does network address transaltion for instances w/ public IPv4 addresses
resource "aws_internet_gateway" "dbt_igw" {
  vpc_id = aws_vpc.dbt_vpc.id

  tags = {
    Name = "dbt_igw"
  }
  depends_on = [
    aws_vpc.dbt_vpc
  ]

}


resource "aws_route_table" "dbt_vpc_public_route_table" {
  vpc_id = aws_vpc.dbt_vpc.id

  tags = {
    Name = "dbt-routing-table-public"
  }
}

resource "aws_subnet" "dbt_public_subnet" {
  vpc_id     = aws_vpc.dbt_vpc.id
  cidr_block = "10.0.0.0/24"
  map_public_ip_on_launch = true 

  tags = {
    Name = "dbt_public_subnet"
  }
}

resource "aws_route" "dbt_vpc_public" {
  route_table_id         = aws_route_table.dbt_vpc_public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.dbt_igw.id
}


#Allows traffic from IG to public subnet in VPC
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.dbt_public_subnet.id
  route_table_id = aws_route_table.dbt_vpc_public_route_table.id
}


resource "aws_security_group" "dbt_vpc_security_group" {
  name        = "dbt_vpc_security_group"
  description = "ECS Allowed Ports"
  vpc_id      = aws_vpc.dbt_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}