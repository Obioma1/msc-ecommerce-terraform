
# API Gateway HTTP API

resource "aws_apigatewayv2_api" "ecommerce" {
  name          = "${var.project_name}-api"
  protocol_type = "HTTP"

  # Allow the CloudFront-hosted frontend to call the API.
  cors_configuration {
    allow_origins = ["*"]

    allow_methods = [
      "GET",
      "POST",
      "OPTIONS"
    ]

    allow_headers = [
      "content-type"
    ]

    max_age = 300
  }

  tags = {
    Name = "${var.project_name}-api"
  }
}

# Default stage with automatic deployment

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.ecommerce.id
  name        = "$default"
  auto_deploy = true
}

# Lambda integrations

resource "aws_apigatewayv2_integration" "get_products" {
  api_id                 = aws_apigatewayv2_api.ecommerce.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.get_products.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "cart" {
  api_id                 = aws_apigatewayv2_api.ecommerce.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.cart.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "order" {
  api_id                 = aws_apigatewayv2_api.ecommerce.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.order.invoke_arn
  payload_format_version = "2.0"
}

# API routes

resource "aws_apigatewayv2_route" "get_products" {
  api_id    = aws_apigatewayv2_api.ecommerce.id
  route_key = "GET /products"
  target    = "integrations/${aws_apigatewayv2_integration.get_products.id}"
}

resource "aws_apigatewayv2_route" "post_cart" {
  api_id    = aws_apigatewayv2_api.ecommerce.id
  route_key = "POST /cart"
  target    = "integrations/${aws_apigatewayv2_integration.cart.id}"
}

resource "aws_apigatewayv2_route" "get_cart" {
  api_id    = aws_apigatewayv2_api.ecommerce.id
  route_key = "GET /cart/{id}"
  target    = "integrations/${aws_apigatewayv2_integration.cart.id}"
}

resource "aws_apigatewayv2_route" "post_orders" {
  api_id    = aws_apigatewayv2_api.ecommerce.id
  route_key = "POST /orders"
  target    = "integrations/${aws_apigatewayv2_integration.order.id}"
}

# Allow API Gateway to invoke Lambda functions

resource "aws_lambda_permission" "get_products" {
  statement_id  = "AllowAPIGatewayGetProducts"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_products.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.ecommerce.execution_arn}/*/*"
}

resource "aws_lambda_permission" "cart" {
  statement_id  = "AllowAPIGatewayCart"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cart.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.ecommerce.execution_arn}/*/*"
}

resource "aws_lambda_permission" "order" {
  statement_id  = "AllowAPIGatewayOrder"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.order.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.ecommerce.execution_arn}/*/*"
}

