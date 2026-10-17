# ------------------------------------------------------------
# Frontend Hosting
# Private S3 bucket for the e-commerce website
# ------------------------------------------------------------

resource "aws_s3_bucket" "frontend" {
  bucket = "${var.project_name}-frontend-${data.aws_caller_identity.current.account_id}-${var.aws_region}"

  tags = {
    Name    = "${var.project_name}-frontend"
    Purpose = "E-commerce frontend website"
  }
}

# Disable ACLs and enforce bucket ownership.

resource "aws_s3_bucket_ownership_controls" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# Prevent direct public access to the frontend bucket.

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable server-side encryption.

resource "aws_s3_bucket_server_side_encryption_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ------------------------------------------------------------
# Upload frontend index.html to S3
# Replace the API placeholder with the deployed API URL
# ------------------------------------------------------------

resource "aws_s3_object" "frontend_index" {
  bucket = aws_s3_bucket.frontend.id
  key    = "index.html"

  content = replace(
    file("${path.module}/frontend/index.html"),
    "__API_GATEWAY_URL__",
    trimsuffix(aws_apigatewayv2_stage.default.invoke_url, "/")
  )

  content_type = "text/html; charset=utf-8"

  etag = md5(replace(
    file("${path.module}/frontend/index.html"),
    "__API_GATEWAY_URL__",
    trimsuffix(aws_apigatewayv2_stage.default.invoke_url, "/")
  ))
}
