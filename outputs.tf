output "deployment_region" {
  description = "AWS region used for this deployment."
  value       = var.aws_region
}

output "project_name" {
  description = "Project name used for AWS resources."
  value       = var.project_name
}

output "serverless_api_url" {
  description = "Public URL of the serverless HTTP API."
  value       = try(aws_apigatewayv2_stage.default.invoke_url, null)
}

output "traditional_alb_dns_name" {
  description = "DNS name of the traditional EC2 Application Load Balancer."
  value       = try(aws_lb.ecommerce.dns_name, null)
}

output "products_table_name" {
  description = "DynamoDB Products table."
  value       = try(aws_dynamodb_table.products.name, null)
}

output "carts_table_name" {
  description = "DynamoDB Carts table."
  value       = try(aws_dynamodb_table.carts.name, null)
}

output "orders_table_name" {
  description = "DynamoDB Orders table."
  value       = try(aws_dynamodb_table.orders.name, null)
}


# CloudFront HTTPS website URL

output "frontend_website_url" {
  description = "Public HTTPS URL for the e-commerce frontend."
  value       = "https://${aws_cloudfront_distribution.frontend.domain_name}"
}

