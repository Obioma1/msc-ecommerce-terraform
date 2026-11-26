# --------------------------------------------------
# S3 Bucket for Terraform Remote State
# --------------------------------------------------

resource "aws_s3_bucket" "terraform_state" {
  bucket        = "obiom-msc-ecommerce-terraform-state"
  force_destroy = false

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name      = "Terraform State Backend"
    Project   = "msc-ecommerce"
    Purpose   = "Remote State Storage"
    ManagedBy = "Terraform"
  }
}

# --------------------------------------------------
# Enable S3 Bucket Versioning
# --------------------------------------------------

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# --------------------------------------------------
# Enable Server-Side Encryption
# --------------------------------------------------

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# --------------------------------------------------
# Block All Public Access
# --------------------------------------------------

resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}