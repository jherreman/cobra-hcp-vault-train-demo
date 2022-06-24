#Configure AWS Networking components (VPC, TGW)

resource "aws_vpc" "vault-vpc" {
  provider             = aws.primaryregion
  cidr_block           = "172.29.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    "Name" = "cbeck-vault-train-demo-vpc"
  }
}

resource "aws_internet_gateway" "gw" {
  provider = aws.primaryregion
  vpc_id   = aws_vpc.vault-vpc.id
}

resource "aws_subnet" "vault-subnet-primary" {
  provider                = aws.primaryregion
  vpc_id                  = aws_vpc.vault-vpc.id
  cidr_block              = "172.29.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
}

resource "aws_ec2_transit_gateway" "vault-tgw" {
  provider = aws.primaryregion
  tags = {
    "Name" = "cbeck-vault-train-demo-tgw"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "vault-vpc-attachment" {
  provider           = aws.primaryregion
  subnet_ids         = [aws_subnet.vault-subnet-primary.id]
  transit_gateway_id = aws_ec2_transit_gateway.vault-tgw.id
  vpc_id             = aws_vpc.vault-vpc.id
}

resource "aws_ram_resource_share" "vault-resource-share" {
  provider                  = aws.primaryregion
  name                      = "vault-train-demo-resource-share"
  allow_external_principals = true
}

resource "aws_ram_principal_association" "vault-ram-prin-assoc" {
  provider           = aws.primaryregion
  resource_share_arn = aws_ram_resource_share.vault-resource-share.arn
  principal          = hcp_hvn.vault-hvn-primary.provider_account_id
}

resource "aws_ram_resource_association" "vault-ram-rec-assoc" {
  provider           = aws.primaryregion
  resource_arn       = aws_ec2_transit_gateway.vault-tgw.arn
  resource_share_arn = aws_ram_resource_share.vault-resource-share.arn
}

resource "aws_ec2_transit_gateway_vpc_attachment_accepter" "tgw-accept" {
  provider                      = aws.primaryregion
  transit_gateway_attachment_id = hcp_aws_transit_gateway_attachment.vault-hcp-tgwa.provider_transit_gateway_attachment_id
}

resource "aws_security_group" "vaultsg" {
  provider    = aws.primaryregion
  name        = "cbeck Vault Security"
  description = "Vault Security Group"
  vpc_id      = aws_vpc.vault-vpc.id

  ingress {
    description = "All traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.vault-vpc.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "cbeck_ec2_sg"
  }
}

resource "aws_route_table" "rt" {
  provider = aws.primaryregion
  vpc_id   = aws_vpc.vault-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "cbeck_rt"
  }
}

resource "aws_main_route_table_association" "a" {
  provider       = aws.primaryregion
  vpc_id         = aws_vpc.vault-vpc.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_route" "vpcroute" {
  provider               = aws.primaryregion
  destination_cidr_block = hcp_hvn.vault-hvn-primary.cidr_block
  transit_gateway_id     = aws_ec2_transit_gateway.vault-tgw.id
  route_table_id         = aws_route_table.rt.id

  depends_on = [
    aws_ec2_transit_gateway_vpc_attachment.vault-vpc-attachment
  ]
}

resource "aws_route_table_association" "mainrt" {
  provider       = aws.primaryregion
  subnet_id      = aws_subnet.vault-subnet-primary.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_ec2_transit_gateway_route_table" "vault-tgw-route-table" {
  provider           = aws.primaryregion
  transit_gateway_id = aws_ec2_transit_gateway.vault-tgw.id
}

resource "aws_ec2_transit_gateway_route" "vault-tgw-route" {
  provider                       = aws.primaryregion
  destination_cidr_block         = hcp_hvn.vault-hvn-primary.cidr_block
  transit_gateway_attachment_id  = hcp_aws_transit_gateway_attachment.primary-vault-hcp-tgwa.provider_transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.vault-tgw-route-table.id

  depends_on = [
    aws_ec2_transit_gateway_vpc_attachment_accepter.tgw-accept
  ]
}
