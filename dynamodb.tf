# ------------------------------------------------------------
# DynamoDB
# Shared data layer for both cloud architectures
# ------------------------------------------------------------

# Products table
resource "aws_dynamodb_table" "products" {
  name         = "Products"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "ProductId"

  attribute {
    name = "ProductId"
    type = "S"
  }

  tags = {
    Name    = "Products"
    Purpose = "Shared e-commerce product catalogue"
  }
}

# Carts table
resource "aws_dynamodb_table" "carts" {
  name         = "Carts"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "CartId"

  attribute {
    name = "CartId"
    type = "S"
  }

  tags = {
    Name    = "Carts"
    Purpose = "Shared e-commerce shopping carts"
  }
}

# Orders table
resource "aws_dynamodb_table" "orders" {
  name         = "Orders"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "OrderId"

  attribute {
    name = "OrderId"
    type = "S"
  }

  tags = {
    Name    = "Orders"
    Purpose = "Shared e-commerce orders"
  }
}

# ------------------------------------------------------------
# Initial Product Dataset
# ------------------------------------------------------------

resource "aws_dynamodb_table_item" "product_laptop" {
  table_name = aws_dynamodb_table.products.name
  hash_key   = aws_dynamodb_table.products.hash_key

  item = jsonencode({
    ProductId = {
      S = "P001"
    }
    Name = {
      S = "Laptop"
    }
    Description = {
      S = "15-inch laptop computer"
    }
    Price = {
      N = "799.99"
    }
    StockQuantity = {
      N = "25"
    }
    ImageKey = {
      S = "laptop.jpg"
    }
  })
}

resource "aws_dynamodb_table_item" "product_smartphone" {
  table_name = aws_dynamodb_table.products.name
  hash_key   = aws_dynamodb_table.products.hash_key

  item = jsonencode({
    ProductId = {
      S = "P002"
    }
    Name = {
      S = "Smartphone"
    }
    Description = {
      S = "6.5-inch smartphone"
    }
    Price = {
      N = "599.99"
    }
    StockQuantity = {
      N = "40"
    }
    ImageKey = {
      S = "smartphone.jpg"
    }
  })
}

resource "aws_dynamodb_table_item" "product_headphones" {
  table_name = aws_dynamodb_table.products.name
  hash_key   = aws_dynamodb_table.products.hash_key

  item = jsonencode({
    ProductId = {
      S = "P003"
    }
    Name = {
      S = "Headphones"
    }
    Description = {
      S = "Wireless headphones"
    }
    Price = {
      N = "129.99"
    }
    StockQuantity = {
      N = "60"
    }
    ImageKey = {
      S = "headphones.jpg"
    }
  })
}

resource "aws_dynamodb_table_item" "product_monitor" {
  table_name = aws_dynamodb_table.products.name
  hash_key   = aws_dynamodb_table.products.hash_key

  item = jsonencode({
    ProductId = {
      S = "P004"
    }
    Name = {
      S = "Monitor"
    }
    Description = {
      S = "27-inch computer monitor"
    }
    Price = {
      N = "249.99"
    }
    StockQuantity = {
      N = "30"
    }
    ImageKey = {
      S = "monitor.jpg"
    }
  })
}

resource "aws_dynamodb_table_item" "product_keyboard" {
  table_name = aws_dynamodb_table.products.name
  hash_key   = aws_dynamodb_table.products.hash_key

  item = jsonencode({
    ProductId = {
      S = "P005"
    }
    Name = {
      S = "Keyboard"
    }
    Description = {
      S = "Wireless keyboard"
    }
    Price = {
      N = "69.99"
    }
    StockQuantity = {
      N = "50"
    }
    ImageKey = {
      S = "keyboard.jpg"
    }
  })
}
