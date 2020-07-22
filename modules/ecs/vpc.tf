# VPC

# STEP1: VPCの設定
# https://www.terraform.io/docs/providers/aws/r/vpc.html

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "${var.prefix}-vpc"
  }
}


# STEP2: パブリックサブネットを立てる
# 上で作成したVPCを参照し、そのVPC内にサブネットを立てる
# ap-northeast-1aには、Availability Zoneが3つあるので、3つに対してサブネットを立てる
# https://www.terraform.io/docs/providers/aws/r/subnet.html

resource "aws_subnet" "public_1a" {
  vpc_id = aws_vpc.main.id

  availability_zone = "ap-northeast-1a"

  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "${var.prefix}-public-1a"
  }
}

resource "aws_subnet" "public_1c" {
  vpc_id = aws_vpc.main.id

  availability_zone = "ap-northeast-1c"

  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "${var.prefix}-public-1c"
  }
}

resource "aws_subnet" "public_1d" {
  vpc_id = aws_vpc.main.id

  availability_zone = "ap-northeast-1d"

  cidr_block = "10.0.3.0/24"

  tags = {
    Name = "${var.prefix}-public-1d"
  }
}


# STEP3: プライベートサブネットを立てる

resource "aws_subnet" "private_1a" {
  vpc_id = aws_vpc.main.id

  availability_zone = "ap-northeast-1a"

  cidr_block = "10.0.10.0/24"

  tags = {
    Name = "${var.prefix}-private-1a"
  }
}

resource "aws_subnet" "private_1c" {
  vpc_id = aws_vpc.main.id

  availability_zone = "ap-northeast-1c"

  cidr_block = "10.0.20.0/24"

  tags = {
    Name = "${var.prefix}-private-1c"
  }
}

resource "aws_subnet" "private_1d" {
  vpc_id = aws_vpc.main.id

  availability_zone = "ap-northeast-1d"

  cidr_block = "10.0.30.0/24"

  tags = {
    Name = "${var.prefix}-private-1d"
  }
}


# STEP3: インターネットゲートウェイ
# VPC内から、外部インターネットと接続するためのゲートウェイ。これを使うことで、VPC内のシステムがグローバルIPを使えるようになります。
# https://www.terraform.io/docs/providers/aws/r/internet_gateway.html

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.prefix}-igw"
  }
}


# STEP4: Elastic IPを取得して、NATゲートウェイを作成
# NAT Gateway には1つの Elastic IP が必要なので作成
# https://www.terraform.io/docs/providers/aws/r/eip.html

resource "aws_eip" "nat_1a" {
  vpc = true

  tags = {
    Name = "${var.prefix}-eip-for-natgw-1a"
  }
}

# subnet_idで作成済みサブネットIDを、allocation_idで公開IPを指定
# https://www.terraform.io/docs/providers/aws/r/nat_gateway.html
resource "aws_nat_gateway" "nat_1a" {
  subnet_id     = aws_subnet.public_1a.id
  allocation_id = aws_eip.nat_1a.id

  tags = {
    Name = "${var.prefix}-natgw-1a"
  }
}

# 以下、1c〜1dの処理

resource "aws_eip" "nat_1c" {
  vpc = true

  tags = {
    Name = "${var.prefix}-eip-for-natgw-1c"
  }
}

resource "aws_nat_gateway" "nat_1c" {
  subnet_id     = aws_subnet.public_1c.id
  allocation_id = aws_eip.nat_1c.id

  tags = {
    Name = "${var.prefix}-natgw-1c"
  }
}

resource "aws_eip" "nat_1d" {
  vpc = true

  tags = {
    Name = "${var.prefix}-eip-for-natgw-1d"
  }
}

resource "aws_nat_gateway" "nat_1d" {
  subnet_id     = aws_subnet.public_1d.id
  allocation_id = aws_eip.nat_1d.id

  tags = {
    Name = "${var.prefix}-natgw-1d"
  }
}



# STEP5: Route Table
# https://www.terraform.io/docs/providers/aws/r/route_table.html

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.prefix}-public-route-table"
  }
}



# STEP6: Route
# https://www.terraform.io/docs/providers/aws/r/route.html

resource "aws_route" "public" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.main.id
}



# STEP7: Association
# https://www.terraform.io/docs/providers/aws/r/route_table_association.html

resource "aws_route_table_association" "public_1a" {
  subnet_id      = aws_subnet.public_1a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_1c" {
  subnet_id      = aws_subnet.public_1c.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_1d" {
  subnet_id      = aws_subnet.public_1d.id
  route_table_id = aws_route_table.public.id
}



# STEP8: Route Table (Private)
# https://www.terraform.io/docs/providers/aws/r/route_table.html

resource "aws_route_table" "private_1a" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.prefix}-private-1a"
  }
}

resource "aws_route_table" "private_1c" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.prefix}-private-1c"
  }
}

resource "aws_route_table" "private_1d" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.prefix}-private-1d"
  }
}



# Route (Private)
# https://www.terraform.io/docs/providers/aws/r/route.html

resource "aws_route" "private_1a" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.private_1a.id
  nat_gateway_id         = aws_nat_gateway.nat_1a.id
}

resource "aws_route" "private_1c" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.private_1c.id
  nat_gateway_id         = aws_nat_gateway.nat_1c.id
}

resource "aws_route" "private_1d" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.private_1d.id
  nat_gateway_id         = aws_nat_gateway.nat_1d.id
}



# Association (Private)
# https://www.terraform.io/docs/providers/aws/r/route_table_association.html

resource "aws_route_table_association" "private_1a" {
  subnet_id      = aws_subnet.private_1a.id
  route_table_id = aws_route_table.private_1a.id
}

resource "aws_route_table_association" "private_1c" {
  subnet_id      = aws_subnet.private_1c.id
  route_table_id = aws_route_table.private_1c.id
}

resource "aws_route_table_association" "private_1d" {
  subnet_id      = aws_subnet.private_1d.id
  route_table_id = aws_route_table.private_1d.id
}