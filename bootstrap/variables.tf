variable "aws_region" {
  description = "AWS region for all bootstrap resources."
  type        = string
  default     = "us-east-1"
}

variable "state_bucket_name" {
  description = "Globally unique name for the S3 bucket holding Terraform remote state."
  type        = string
}

variable "kms_key_alias" {
  description = "Alias of the existing customer-managed KMS key used to encrypt the state bucket."
  type        = string
  default     = "project-encryption-key"
}

variable "github_owner" {
  description = "GitHub user or organisation that owns the repo (left side of owner/repo)."
  type        = string
  default     = "patrick-anderson-555"
}

variable "github_repo" {
  description = "GitHub repository name (right side of owner/repo)."
  type        = string
  default     = "aws-security-iac"
}