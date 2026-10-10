output "state_bucket_name" {
  description = "Name of the S3 bucket holding Terraform remote state. Use in environments/*/terraform.tf backend config."
  value       = aws_s3_bucket.state.id
}

output "state_bucket_arn" {
  description = "ARN of the state bucket."
  value       = aws_s3_bucket.state.arn
}

output "state_kms_key_arn" {
  description = "ARN of the KMS key encrypting the state bucket."
  value       = data.aws_kms_key.state.arn
}

output "github_plan_role_arn" {
  description = "ARN of the IAM role GitHub Actions PR workflows assume for terraform plan. Set as a GitHub Actions variable."
  value       = aws_iam_role.github_plan.arn
}

output "github_apply_role_arn" {
  description = "ARN of the IAM role GitHub Actions main-branch workflows assume for terraform apply. Set as a GitHub Actions variable."
  value       = aws_iam_role.github_apply.arn
}

output "github_oidc_provider_arn" {
  description = "ARN of the GitHub OIDC identity provider."
  value       = aws_iam_openid_connect_provider.github.arn
}