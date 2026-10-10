terraform {
  required_version = ">= 1.11.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.100"
    }
  }

  backend "s3" {
    bucket       = "patrick-tfstate-163475281977-us-east-1"
    key          = "environments/dev/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    kms_key_id   = "arn:aws:kms:us-east-1:163475281977:key/74424019-7db7-42a7-852d-7892c355991e"
    use_lockfile = true
  }
}