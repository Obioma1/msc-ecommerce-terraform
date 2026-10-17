
# ------------------------------------------------------------
# AWS Lambda Functions
# Serverless E-Commerce Architecture
# ------------------------------------------------------------

# ------------------------------------------------------------
# Package Lambda function source files
# ------------------------------------------------------------

data "archive_file" "get_products" {
  type        = "zip"
  source_file = "${path.module}/lambda/get_products/lambda_function.py"
  output_path = "${path.module}/lambda/get_products/get_products.zip"
}

data "archive_file" "cart" {
  type        = "zip"
  source_file = "${path.module}/lambda/cart/lambda_function.py"
  output_path = "${path.module}/lambda/cart/cart.zip"
}

data "archive_file" "order" {
  type        = "zip"
  source_file = "${path.module}/lambda/order/lambda_function.py"
  output_path = "${path.module}/lambda/order/order.zip"
}

# ------------------------------------------------------------
# Lambda Function 1: Get Products
# Retrieves products from DynamoDB and generates
# presigned S3 URLs for product images.
# ------------------------------------------------------------

resource "aws_lambda_function" "get_products" {
  function_name = "${var.project_name}-get-products"

  role    = aws_iam_role.lambda_execution_role.arn
  runtime = "python3.12"
  handler = "lambda_function.lambda_handler"

  filename         = data.archive_file.get_products.output_path
  source_code_hash = data.archive_file.get_products.output_base64sha256

  memory_size = 128
  timeout     = 30

  environment {
    variables = {
      PRODUCTS_TABLE = aws_dynamodb_table.products.name
      BUCKET_NAME    = aws_s3_bucket.ecommerce_images.bucket
    }
  }

  # Ensure IAM permissions exist before Lambda deployment.
  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_iam_role_policy.lambda_dynamodb_policy,
    aws_iam_role_policy.lambda_s3_policy
  ]

  tags = {
    Name = "${var.project_name}-get-products"
  }
}

# ------------------------------------------------------------
# Lambda Function 2: Shopping Cart
# Handles cart operations using DynamoDB.
# ------------------------------------------------------------

resource "aws_lambda_function" "cart" {
  function_name = "${var.project_name}-cart"

  role    = aws_iam_role.lambda_execution_role.arn
  runtime = "python3.12"
  handler = "lambda_function.lambda_handler"

  filename         = data.archive_file.cart.output_path
  source_code_hash = data.archive_file.cart.output_base64sha256

  memory_size = 128
  timeout     = 30

  environment {
    variables = {
      CARTS_TABLE = aws_dynamodb_table.carts.name
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_iam_role_policy.lambda_dynamodb_policy
  ]

  tags = {
    Name = "${var.project_name}-cart"
  }
}

# ------------------------------------------------------------
# Lambda Function 3: Order Processing
# Handles order placement using DynamoDB.
# ------------------------------------------------------------

resource "aws_lambda_function" "order" {
  function_name = "${var.project_name}-order"

  role    = aws_iam_role.lambda_execution_role.arn
  runtime = "python3.12"
  handler = "lambda_function.lambda_handler"

  filename         = data.archive_file.order.output_path
  source_code_hash = data.archive_file.order.output_base64sha256

  memory_size = 128
  timeout     = 30

  environment {
    variables = {
      ORDERS_TABLE = aws_dynamodb_table.orders.name
      CARTS_TABLE  = aws_dynamodb_table.carts.name
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_iam_role_policy.lambda_dynamodb_policy
  ]

  tags = {
    Name = "${var.project_name}-order"
  }
}

