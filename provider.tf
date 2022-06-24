#Declare required providers and connect to TFCB workspace
terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 4.0"
    }
    hcp = {
        source = "hashicorp/hcp"
        version = "~> 0.29.0"
    }
  }
  cloud {
      organization = "chrisbeck"
      workspaces {
          name = "cobra-hcp-vault-train-demo"
      }
  }
}

#Configure AWS provider
provider "aws" {
    region = var.primaryawsregion
    alias = "primaryregion"
}

provider "aws" {
  region = var.secondaryawsregion
  alias = "secondaryregion"
}

#Configure HCP provider
provider "hcp" {

}
