output "state_bucket_name" {
  description = "Name of the S3 bucket for Terraform remote state"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "state_bucket_arn" {
  description = "ARN of the Terraform state bucket"
  value       = aws_s3_bucket.terraform_state.arn
}

output "state_bucket_region" {
  description = "AWS region of the Terraform state bucket"
  value       = aws_s3_bucket.terraform_state.region
}