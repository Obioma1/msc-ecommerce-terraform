import json
import boto3
from decimal import Decimal

dynamodb = boto3.resource('dynamodb')

orders_table = dynamodb.Table('Orders')
carts_table = dynamodb.Table('Carts')
products_table = dynamodb.Table('Products')


class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        return super(DecimalEncoder, self).default(obj)


def lambda_handler(event, context):
    try:
        request_context = event.get('requestContext', {})
        http = request_context.get('http', {})
        method = http.get('method', '')

        path_parameters = event.get('pathParameters') or {}
        order_id = path_parameters.get('id')

        # -------------------------------------------------
        # POST /orders
        # Create an order from an existing shopping cart.
        # -------------------------------------------------
        if method == 'POST':

            body = json.loads(event.get('body') or '{}')

            order_id = body.get('OrderId')
            cart_id = body.get('CartId')

            if not order_id or not cart_id:
                return response(
                    400,
                    {
                        'message':
                        'OrderId and CartId are required'
                    }
                )

            # Check whether this OrderId already exists.
            existing_order = orders_table.get_item(
                Key={'OrderId': order_id}
            ).get('Item')

            if existing_order:
                return response(
                    409,
                    {'message': 'OrderId already exists'}
                )

            # Retrieve the cart.
            cart_result = carts_table.get_item(
                Key={'CartId': cart_id}
            )

            cart = cart_result.get('Item')

            if not cart:
                return response(
                    404,
                    {'message': 'Cart not found'}
                )

            cart_items = cart.get('Items', [])

            if not cart_items:
                return response(
                    400,
                    {'message': 'Cart is empty'}
                )

            order_items = []
            total_amount = Decimal('0')

            # Validate every product and calculate
            # the total using server-side product prices.
            for cart_item in cart_items:

                product_id = cart_item.get('ProductId')
                quantity = Decimal(
                    str(cart_item.get('Quantity', 0))
                )

                if not product_id or quantity <= 0:
                    return response(
                        400,
                        {'message': 'Invalid item in cart'}
                    )

                product_result = products_table.get_item(
                    Key={'ProductId': product_id}
                )

                product = product_result.get('Item')

                if not product:
                    return response(
                        404,
                        {
                            'message':
                            f'Product {product_id} not found'
                        }
                    )

                stock_quantity = Decimal(
                    str(product.get('StockQuantity', 0))
                )

                price = Decimal(
                    str(product.get('Price', 0))
                )

                if stock_quantity < quantity:
                    return response(
                        400,
                        {
                            'message':
                            f'Insufficient stock for '
                            f'{product_id}'
                        }
                    )

                line_total = price * quantity
                total_amount += line_total

                order_items.append(
                    {
                        'ProductId': product_id,
                        'ProductName': product.get(
                            'Name',
                            product_id
                        ),
                        'Quantity': quantity,
                        'UnitPrice': price,
                        'LineTotal': line_total
                    }
                )

            # All products have passed validation.
            # Reduce stock for each purchased product.
            for order_item in order_items:

                products_table.update_item(
                    Key={
                        'ProductId':
                        order_item['ProductId']
                    },
                    UpdateExpression=(
                        'SET StockQuantity = '
                        'StockQuantity - :quantity'
                    ),
                    ExpressionAttributeValues={
                        ':quantity':
                        order_item['Quantity']
                    }
                )

            # Store the completed order.
            order = {
                'OrderId': order_id,
                'CartId': cart_id,
                'Items': order_items,
                'TotalAmount': total_amount,
                'Status': 'PLACED'
            }

            orders_table.put_item(Item=order)

            return response(201, order)

        # -------------------------------------------------
        # GET /orders/{id}
        # Retrieve an existing order.
        # -------------------------------------------------
        elif method == 'GET':

            if not order_id:
                return response(
                    400,
                    {'message': 'OrderId is required'}
                )

            result = orders_table.get_item(
                Key={'OrderId': order_id}
            )

            order = result.get('Item')

            if not order:
                return response(
                    404,
                    {'message': 'Order not found'}
                )

            return response(200, order)

        else:
            return response(
                405,
                {'message': 'Method not allowed'}
            )

    except json.JSONDecodeError:
        return response(
            400,
            {'message': 'Invalid JSON request body'}
        )

    except Exception as e:
        print(f'OrderFunction error: {str(e)}')

        return response(
            500,
            {'message': 'Internal server error'}
        )


def response(status_code, body):
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json'
        },
        'body': json.dumps(
            body,
            cls=DecimalEncoder
        )
    }
