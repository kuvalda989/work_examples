# Generated by Terragrunt. Sig: nIlQXj57tbuaRZEa
terraform {
  backend "s3" {
    bucket         = "terraform-states-557064355951"
    dynamodb_table = "my-lock-table"
    encrypt        = true
    key            = "./terraform.tfstate"
    region         = "eu-central-1"
  }
}
