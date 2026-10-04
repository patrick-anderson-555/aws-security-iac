# --- Networking ---
data "aws_caller_identity" "current" {}

data "aws_kms_key" "project" {
  key_id = "alias/${var.kms_key_alias}"
}
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags       = { Name = "checkov-practice-vpc" }
}

resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  tags       = { Name = "checkov-practice-subnet" }
}

# Lock down the auto-created default security group so stray resources
# that end up in it get no network access.
resource "aws_default_security_group" "main" {
  vpc_id = aws_vpc.main.id
}

# --- Flow logs ---
resource "aws_cloudwatch_log_group" "flow_log" {
  name              = "/aws/vpc-flow-log/checkov-practice"
  retention_in_days = 365
  kms_key_id        = data.aws_kms_key.project.arn
}

resource "aws_iam_role" "flow_log" {
  name = "checkov-practice-flow-log-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "vpc-flow-logs.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "flow_log" {
  name = "checkov-practice-flow-log-policy"
  role = aws_iam_role.flow_log.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams"
      ]
      Resource = "${aws_cloudwatch_log_group.flow_log.arn}:*"
    }]
  })
}

resource "aws_flow_log" "main" {
  iam_role_arn    = aws_iam_role.flow_log.arn
  log_destination = aws_cloudwatch_log_group.flow_log.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id
}

# --- Application security group ---
resource "aws_security_group" "web" {
  name        = "checkov-practice-sg"
  description = "Allow SSH from the office VPN and HTTPS egress"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from office VPN only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.100.0.0/24"]
  }

  egress {
    description = "HTTPS to anywhere for package updates and API calls"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- S3 bucket and its sidecar protections ---
resource "aws_s3_bucket" "data" {
  bucket = "checkov-practice-${data.aws_caller_identity.current.account_id}"
  # checkov:skip=CKV_AWS_18:Access logging would be centralized in a shared logging account; out of scope for this practice project
  # checkov:skip=CKV_AWS_144:Cross-region replication not needed; this bucket's data is not critical enough to justify the cost
  # checkov:skip=CKV2_AWS_61:No lifecycle rule needed; this bucket holds reference data retained indefinitely
  # checkov:skip=CKV2_AWS_62:Event notifications not needed; this is a static-data bucket with no event consumers
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket_public_access_block" "data" {
  bucket                  = aws_s3_bucket.data.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data" {
  bucket = aws_s3_bucket.data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = data.aws_kms_key.project.arn
    }
  }
}

resource "aws_s3_bucket_versioning" "data" {
  bucket = aws_s3_bucket.data.id
  versioning_configuration {
    status = "Enabled"
  }
}

# --- IAM role for the EC2 instance ---
resource "aws_iam_role" "app" {
  name = "checkov-practice-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "app" {
  name = "checkov-practice-policy"
  role = aws_iam_role.app.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:PutObject"
      ]
      Resource = "${aws_s3_bucket.data.arn}/*"
    }]
  })
}

resource "aws_iam_instance_profile" "app" {
  name = "checkov-practice-profile"
  role = aws_iam_role.app.name
}

# --- EC2 instance ---
resource "aws_instance" "web" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.main.id
  vpc_security_group_ids = [aws_security_group.web.id]
  iam_instance_profile   = aws_iam_instance_profile.app.name

  monitoring    = true
  ebs_optimized = true

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    encrypted = true
  }

  tags = { Name = "checkov-practice-instance" }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
  owners = ["099720109477"]
}