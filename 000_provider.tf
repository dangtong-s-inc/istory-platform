## AWS Provider 설정
provider "aws" {
  profile = var.terraform_aws_profile
  # access_key = var.aws_access_key_id
  # secret_key = var.aws_secret_access_key
  region = var.aws_region
  default_tags {
    tags = {
      managed_by = "terraform"
    }
  }
}