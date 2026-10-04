variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}
variable "kms_key_alias" {
  description = "Alias of the KMS key used for encrypting resources in this environment"
  type        = string
  default     = "project-encryption-key"
}