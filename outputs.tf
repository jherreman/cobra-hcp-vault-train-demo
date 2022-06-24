output "instance" {
  value = aws_instance.vaultsrv01.public_ip
}

output "hcp-priv-addr" {
    value = hcp_vault_cluster.vault-east.vault_private_endpoint_url
}

output "hcp-pub-addr" {
  value = hcp_vault_cluster.vault-east.vault_public_endpoint_url
}