provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = "aws-security-iac"
      Environment = "bootstrap"
      ManagedBy   = "terraform"
      Repo        = "patrick-anderson-555/aws-security-iac"
    }
  }
}