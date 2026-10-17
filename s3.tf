# ------------------------------------------------------------
# Amazon S3
# Shared private object storage for both architectures
# ------------------------------------------------------------

# Retrieve information about the current AWS account.
# This allows Terraform to create a unique bucket name without
# hard-coding an AWS account identifier.
data "aws_caller_identity" "current" {}

# ------------------------------------------------------------
# S3 Bucket
# ------------------------------------------------------------

resource "aws_s3_bucket" "ecommerce_images" {
  bucket = "${var.project_name}-images-${data.aws_caller_identity.current.account_id}-${var.aws_region}"

  tags = {
    Name    = "${var.project_name}-images"
    Purpose = "Shared e-commerce product image storage"
  }
}

# ------------------------------------------------------------
# Object Ownership
# ACLs are disabled and the bucket owner owns all objects.
# ------------------------------------------------------------

resource "aws_s3_bucket_ownership_controls" "ecommerce_images" {
  bucket = aws_s3_bucket.ecommerce_images.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# ------------------------------------------------------------
# Block All Public Access
# ------------------------------------------------------------

resource "aws_s3_bucket_public_access_block" "ecommerce_images" {
  bucket = aws_s3_bucket.ecommerce_images.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ------------------------------------------------------------
# Server-Side Encryption
# ------------------------------------------------------------

resource "aws_s3_bucket_server_side_encryption_configuration" "ecommerce_images" {
  bucket = aws_s3_bucket.ecommerce_images.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ------------------------------------------------------------
# Versioning
# Disabled for this research prototype.
# ------------------------------------------------------------

resource "aws_s3_bucket_versioning" "ecommerce_images" {
  bucket = aws_s3_bucket.ecommerce_images.id

  versioning_configuration {
    status = "Suspended"
  }
}

# ------------------------------------------------------------
# Upload the five product images to the London S3 bucket
# ------------------------------------------------------------

resource "aws_s3_object" "product_images" {
  for_each = fileset("${path.module}/frontend/images", "*.jpg")

  bucket       = aws_s3_bucket.ecommerce_images.id
  key          = each.value
  source       = "${path.module}/frontend/images/${each.value}"
  etag         = filemd5("${path.module}/frontend/images/${each.value}")
  content_type = "image/jpeg"
}
