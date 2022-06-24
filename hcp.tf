#Configure core HCP components (HVN)

resource "hcp_hvn" "vault-hvn-primary" {
    hvn_id = "vault-train-demo-hvn-primary"
    cloud_provider = var.cloudprovider
    region = var.primaryawsregion
    cidr_block = var.primaryhvncidr
}

resource "hcp_hvn" "vault-hvn-secondary" {
  hvn_id = "vault-train-demo-hvn-secondary"
  cloud_provider = var.cloudprovider
  region = var.secondaryawsregion
  cidr_block = var.secondaryhvncidr
}

resource "hcp_aws_transit_gateway_attachment" "primary-vault-hcp-tgwa" {
  hvn_id = hcp_hvn.vault-hvn-primary.hvn_id
  transit_gateway_attachment_id = "primary-vault-train-tgw-attachment"
  transit_gateway_id = aws_ec2_transit_gateway.vault-tgw.id
  resource_share_arn = aws_ram_resource_share.vault-resource-share.arn

    depends_on = [
    aws_ram_principal_association.vault-ram-prin-assoc,
    aws_ram_resource_association.vault-ram-rec-assoc
  ]
}

resource "hcp_hvn_route" "primary-vault-hvn-route" {
  hvn_link = hcp_hvn.vault-hvn-primary.self_link
  hvn_route_id = "primary-hvn-tgw-route"
  destination_cidr = aws_vpc.vault-vpc.cidr_block
  target_link = hcp_aws_transit_gateway_attachment.primary-vault-hcp-tgwa.self_link

  depends_on = [
    aws_ec2_transit_gateway_vpc_attachment_accepter.tgw-accept
  ]
}

resource "hcp_vault_cluster" "vault-primary" {
  cluster_id = "primary-cluster"
  hvn_id = hcp_hvn.vault-hvn-primary.hvn_id
  tier = "plus_small"
  public_endpoint = var.hcp-vault-public-endpoint
}

resource "hcp_vault_cluster" "vault-secondary" {
  cluster_id = "secondary-cluster"
  hvn_id = hcp_hvn.vault-hvn-secondary.hvn_id
  tier = "plus_small"
  public_endpoint = var.hcp-vault-public-endpoint
  primary_link = hcp_vault_cluster.vault-primary.self_link
}
