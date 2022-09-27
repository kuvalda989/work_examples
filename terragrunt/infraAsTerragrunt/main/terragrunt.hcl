
generate "provider" {
    path = "provider.tf"
    if_exists =  "overwrite_terragrunt"
    contents = <<EOF
provider "aws" {
  region = "eu-central-1"

    default_tags {
    tags = {
      Environment = "Production"
      Owner       = "Ops"
    }
  }
}
EOF
}


remote_state {
  backend      = "s3"
  disable_init = tobool(get_env("TERRAGRUNT_DISABLE_INIT", "false"))

  generate = {
    path      = "_backend.tf"
    if_exists = "overwrite"
  }

  config = {
    encrypt        = true
    region         = "eu-central-1"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    bucket         = format("terraform-states-%s", get_aws_account_id())
    dynamodb_table = "my-lock-table"
  }
}
