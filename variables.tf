# variable "aws_access_key_id" {
#   description = "AWS Access Key ID"
#   type        = string
# }

# variable "aws_secret_access_key" {
#   description = "AWS Secret Access Key"
#   type        = string
# }

variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "ap-northeast-2"  # 기본값 설정 (선택사항)
}

variable "vpc_name" {
  description = "name of vpc"
  type        = string
  default     = "dangtong"
}

variable "cluster_name" {
  description = "name of cluster"
  type        = string
  default     = "istory"
}

variable "cluster_version" {
  description = "version of cluster"
  type        = string
  default     = "1.31"
}

variable "environment" {
  description = "Environment name (e.g., dev, stg, prd)"
  type        = string
  default     = "dev"  # 필요한 경우 기본값 설정
}

variable "terraform_aws_profile" {
  description = "AWS profile for Terraform"
  type        = string
  default     = "aws-cicd"
}