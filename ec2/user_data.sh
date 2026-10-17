#!/bin/bash
set -e
# Save startup output and errors to a dedicated log
exec > >(tee -a /var/log/ecommerce-startup.log) 2>&1

# Identify the command and line if startup fails
trap 'echo "STARTUP FAILED at line $LINENO: $BASH_COMMAND (exit code $?)"' ERR

echo "===== E-commerce startup initiated ====="
date

# ------------------------------------------------------------
# Traditional EC2 E-Commerce Application
# Amazon Linux 2023
# ------------------------------------------------------------

# Install required system packages
dnf install -y python3 python3-pip

# Create application directory
mkdir -p /opt/ecommerce
cd /opt/ecommerce

# ------------------------------------------------------------
# Create the Flask application
# ------------------------------------------------------------

cat > app.py <<'PYEOF'
# from flask import Flask, jsonify, request
# import boto3
# from decimal import Decimal

import os
from flask import Flask, jsonify, request
from flask_cors import CORS
import boto3
from botocore.config import Config
from decimal import Decimal

app = Flask(__name__)

CORS(app)

BUCKET_NAME = os.environ.get("BUCKET_NAME", "")
s3 = boto3.client(
    "s3",
    region_name="${aws_region}",
    endpoint_url="https://s3.${aws_region}.amazonaws.com",
    config=Config(signature_version="s3v4"),
)

dynamodb = boto3.resource("dynamodb", region_name="${aws_region}")

# dynamodb = boto3.resource("dynamodb", region_name="eu-west-2")

products_table = dynamodb.Table("Products")
carts_table = dynamodb.Table("Carts")
orders_table = dynamodb.Table("Orders")


def convert_decimal(value):
    if isinstance(value, list):
        return [convert_decimal(v) for v in value]

    if isinstance(value, dict):
        return {k: convert_decimal(v) for k, v in value.items()}

    if isinstance(value, Decimal):
        return float(value)

    return value


@app.route("/health", methods=["GET"])
def health():
    return jsonify({
        "status": "healthy",
        "architecture": "traditional-ec2"
    }), 200


# GET /products
@app.route("/products", methods=["GET"])
def get_products():
    items = products_table.scan().get("Items", [])

    for product in items:
        image_key = product.get("ImageKey")

        if image_key and BUCKET_NAME:
            product["ImageUrl"] = s3.generate_presigned_url(
                "get_object",
                Params={
                    "Bucket": BUCKET_NAME,
                    "Key": image_key
                },
                ExpiresIn=3600
            )

    return jsonify(convert_decimal(items)), 200


# POST /cart
@app.route("/cart", methods=["POST"])
def add_to_cart():
    try:
        data = request.get_json(force=True)
        cart_id = data.get("CartId")
        product_id = data.get("ProductId")
        quantity = Decimal(str(data.get("Quantity", 1)))

        if not cart_id or not product_id:
            return jsonify({
                "message": "CartId and ProductId are required"
            }), 400

        if quantity <= 0:
            return jsonify({
                "message": "Quantity must be greater than zero"
            }), 400

        product_result = products_table.get_item(
            Key={"ProductId": product_id}
        )

        product = product_result.get("Item")

        if not product:
            return jsonify({"message": "Product not found"}), 404

        cart_result = carts_table.get_item(
            Key={"CartId": cart_id}
        )

        cart = cart_result.get(
            "Item",
            {"CartId": cart_id, "Items": []}
        )

        items = cart.get("Items", [])
        found = False

        for item in items:
            if item.get("ProductId") == product_id:
                item["Quantity"] = (
                    Decimal(str(item.get("Quantity", 0))) + quantity
                )
                found = True
                break

        if not found:
            items.append({
                "ProductId": product_id,
                "Quantity": quantity
            })

        cart["Items"] = items
        carts_table.put_item(Item=cart)

        return jsonify(convert_decimal(cart)), 200

    except Exception as e:
        print(f"Cart error: {str(e)}")
        return jsonify({
            "message": "Internal server error"
        }), 500


# GET /cart/<id>
@app.route("/cart/<cart_id>", methods=["GET"])
def get_cart(cart_id):
    result = carts_table.get_item(
        Key={"CartId": cart_id}
    )

    cart = result.get("Item")

    if not cart:
        return jsonify({
            "CartId": cart_id,
            "Items": []
        }), 200

    return jsonify(convert_decimal(cart)), 200

# DELETE /cart/<id>
@app.route("/cart/<cart_id>", methods=["DELETE"])
def delete_cart(cart_id):
    body = request.get_json(silent=True) or {}
    product_id = body.get("ProductId")

    if not product_id:
        carts_table.delete_item(Key={"CartId": cart_id})
        return jsonify({
            "message": "Cart deleted successfully",
            "CartId": cart_id,
            "Items": []
        }), 200

    cart = carts_table.get_item(Key={"CartId": cart_id}).get("Item")

    if not cart:
        return jsonify({"message": "Cart not found"}), 404

    items = cart.get("Items", [])
    updated = [item for item in items if item.get("ProductId") != product_id]

    if len(updated) == len(items):
        return jsonify({"message": "Product not found in cart"}), 404

    if updated:
        cart["Items"] = updated
        carts_table.put_item(Item=cart)
    else:
        carts_table.delete_item(Key={"CartId": cart_id})

    return jsonify({
        "message": "Product removed from cart",
        "CartId": cart_id,
        "Items": updated
    }), 200

# POST /orders
@app.route("/orders", methods=["POST"])
def create_order():
    try:
        data = request.get_json(force=True)
        order_id = data.get("OrderId")
        cart_id = data.get("CartId")

        if not order_id or not cart_id:
            return jsonify({
                "message": "OrderId and CartId are required"
            }), 400

        existing_order = orders_table.get_item(
            Key={"OrderId": order_id}
        ).get("Item")

        if existing_order:
            return jsonify({
                "message": "OrderId already exists"
            }), 409

        cart_result = carts_table.get_item(
            Key={"CartId": cart_id}
        )

        cart = cart_result.get("Item")

        if not cart:
            return jsonify({"message": "Cart not found"}), 404

        cart_items = cart.get("Items", [])

        if not cart_items:
            return jsonify({"message": "Cart is empty"}), 400

        order_items = []
        total_amount = Decimal("0")

        for cart_item in cart_items:
            product_id = cart_item.get("ProductId")
            quantity = Decimal(
                str(cart_item.get("Quantity", 0))
            )

            if not product_id or quantity <= 0:
                return jsonify({
                    "message": "Invalid item in cart"
                }), 400

            product_result = products_table.get_item(
                Key={"ProductId": product_id}
            )

            product = product_result.get("Item")

            if not product:
                return jsonify({
                    "message": f"Product {product_id} not found"
                }), 404

            stock_quantity = Decimal(
                str(product.get("StockQuantity", 0))
            )

            price = Decimal(
                str(product.get("Price", 0))
            )

            if stock_quantity < quantity:
                return jsonify({
                    "message": f"Insufficient stock for {product_id}"
                }), 400

            line_total = price * quantity
            total_amount += line_total

            order_items.append({
                "ProductId": product_id,
                "ProductName": product.get("Name", product_id),
                "Quantity": quantity,
                "UnitPrice": price,
                "LineTotal": line_total
            })

        for order_item in order_items:
            products_table.update_item(
                Key={
                    "ProductId": order_item["ProductId"]
                },
                UpdateExpression=(
                    "SET StockQuantity = StockQuantity - :quantity"
                ),
                ConditionExpression=(
                    "StockQuantity >= :quantity"
                ),
                ExpressionAttributeValues={
                    ":quantity": order_item["Quantity"]
                }
            )

        order = {
            "OrderId": order_id,
            "CartId": cart_id,
            "Items": order_items,
            "TotalAmount": total_amount,
            "Status": "PLACED"
        }

        orders_table.put_item(Item=order)

        return jsonify(convert_decimal(order)), 201

    except Exception as e:
        print(f"Order error: {str(e)}")
        return jsonify({
            "message": "Internal server error"
        }), 500


# GET /orders/<id>
@app.route("/orders/<order_id>", methods=["GET"])
def get_order(order_id):
    result = orders_table.get_item(
        Key={"OrderId": order_id}
    )

    order = result.get("Item")

    if not order:
        return jsonify({"message": "Order not found"}), 404

    return jsonify(convert_decimal(order)), 200


if __name__ == "__main__":
    app.run(
        host="0.0.0.0",
        port=8080,
        debug=False
    )
PYEOF

# ------------------------------------------------------------
# Create an isolated Python environment
# ------------------------------------------------------------

python3 -m venv /opt/ecommerce/venv

/opt/ecommerce/venv/bin/python -m pip install --upgrade pip
/opt/ecommerce/venv/bin/python -m pip install flask boto3 flask-cors

# ------------------------------------------------------------
# Configure the systemd application service
# ------------------------------------------------------------

cat > /etc/systemd/system/ecommerce.service <<'EOF_SERVICE'
[Unit]
Description=Traditional E-commerce Application
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/ecommerce
ExecStart=/opt/ecommerce/venv/bin/python /opt/ecommerce/app.py
Restart=always
RestartSec=5
Environment=PYTHONUNBUFFERED=1
Environment=AWS_DEFAULT_REGION=${aws_region}
Environment=BUCKET_NAME=${bucket_name}

[Install]
WantedBy=multi-user.target
EOF_SERVICE

# ------------------------------------------------------------
# Start and verify the application
# ------------------------------------------------------------

systemctl daemon-reload
systemctl enable ecommerce.service
systemctl start ecommerce.service

sleep 5

systemctl status ecommerce.service --no-pager || true

# Record application logs for troubleshooting
journalctl -u ecommerce.service --no-pager -n 50 || true

# Verify the local health endpoint
curl --fail --retry 5 --retry-delay 2 \
  http://127.0.0.1:8080/health

echo "Traditional EC2 e-commerce startup completed."

