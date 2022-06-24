variable "primaryawsregion" {
  type = string
  default = "us-east-1"
  description = "Set the AWS region for AWS VPC"
}

variable "secondaryawsregion" {
  type = string
  default = "us-west-1"
  description = "Set the AWS region for AWS VPC"
}

variable "pubkey" {
  type = string
}

variable "cloudprovider" {
  type = string
  default = "aws"
  description = "set cloud provider for hcp"
}

variable "primaryhvncidr" {
  type = string
  default = "172.25.16.0/20"
}

variable "secondaryhvncidr" {
  type = string
  default = "172.26.16.0/20"
}

variable "hcp-vault-public-endpoint" {
  type = bool
  default = false
}