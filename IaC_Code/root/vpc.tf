resource "aws_vpc" "serverless_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = merge(local.common_tags, {
    Name = "serverless_vpc"
  })
}
resource "aws_subnet" "private_rds_a" {
  vpc_id                  = aws_vpc.serverless_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false
  tags = merge(local.common_tags, {
    Name = "private_rds_a"
  })
}

resource "aws_subnet" "private_rds_b" {
  vpc_id                  = aws_vpc.serverless_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = false
  tags = merge(local.common_tags, {
    Name = "private_rds_b"
  })
}

resource "aws_route_table" "private_rds_rt" {
  vpc_id = aws_vpc.serverless_vpc.id
  tags = merge(local.common_tags, {
    Name = "private_rds_rt"
  })

}

resource "aws_route_table_association" "private_rds_a_assoc" {
  subnet_id      = aws_subnet.private_rds_a.id
  route_table_id = aws_route_table.private_rds_rt.id
}

resource "aws_route_table_association" "private_rds_b_assoc" {
  subnet_id      = aws_subnet.private_rds_b.id
  route_table_id = aws_route_table.private_rds_rt.id
}
