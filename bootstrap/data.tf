data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_kms_key" "state" {
  key_id = "alias/${var.kms_key_alias}"
}