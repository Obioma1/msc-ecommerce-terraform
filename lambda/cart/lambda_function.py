import json
import boto3
from decimal import Decimal

# Connect to DynamoDB Carts table
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('Carts')


class DecimalEncoder(json.JSONEncoder):
    """
    Converts DynamoDB Decimal values into normal numbers
    so they can be returned as JSON.
    """
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        return super(DecimalEncoder, self).default(obj)


def lambda_handler(event, context):
    try:
        # ---------------------------------------------------------
        # Read HTTP method from API Gateway HTTP API payload v2.0
        # ---------------------------------------------------------
        request_context = event.get('requestContext', {})
        http = request_context.get('http', {})
        method = http.get('method', '')

        # Read /cart/{id} path parameter
        path_parameters = event.get('pathParameters') or {}
        cart_id = path_parameters.get('id')

        # =========================================================
        # GET /cart/{id}
        # Retrieve an existing cart
        # =========================================================
        if method == 'GET':

            if not cart_id:
                return response(
                    400,
                    {'message': 'CartId is required'}
                )

            result = table.get_item(
                Key={'CartId': cart_id}
            )

            cart = result.get('Item')

            # Returning an empty cart makes the frontend easier
            # to work with when the cart does not yet exist.
            if not cart:
                return response(
                    200,
                    {
                        'CartId': cart_id,
                        'Items': []
                    }
                )

            return response(200, cart)

        # =========================================================
        # POST /cart
        # Add a product to a cart or increase its quantity
        # =========================================================
        elif method == 'POST':

            body = json.loads(event.get('body') or '{}')

            cart_id = body.get('CartId')
            product_id = body.get('ProductId')
            quantity = body.get('Quantity')

            if not cart_id or not product_id or quantity is None:
                return response(
                    400,
                    {
                        'message':
                        'CartId, ProductId and Quantity are required'
                    }
                )

            # DynamoDB requires Decimal rather than Python float
            quantity = Decimal(str(quantity))

            if quantity <= 0:
                return response(
                    400,
                    {'message': 'Quantity must be greater than zero'}
                )

            # Check whether the cart already exists
            result = table.get_item(
                Key={'CartId': cart_id}
            )

            cart = result.get(
                'Item',
                {
                    'CartId': cart_id,
                    'Items': []
                }
            )

            items = cart.get('Items', [])

            # Check whether this product is already in the cart
            existing_item = None

            for item in items:
                if item.get('ProductId') == product_id:
                    existing_item = item
                    break

            # Increase quantity if product already exists
            if existing_item:
                existing_item['Quantity'] += quantity

            # Otherwise add a new product to the cart
            else:
                items.append(
                    {
                        'ProductId': product_id,
                        'Quantity': quantity
                    }
                )

            cart['Items'] = items

            # Save updated cart
            table.put_item(Item=cart)

            return response(200, cart)

        # =========================================================
        # DELETE /cart/{id}
        #
        # Two behaviours are supported:
        #
        # 1. ProductId supplied:
        #    Remove only that product from the cart.
        #
        # 2. No ProductId supplied:
        #    Delete the entire cart.
        # =========================================================
        elif method == 'DELETE':

            if not cart_id:
                return response(
                    400,
                    {'message': 'CartId is required'}
                )

            # DELETE requests may or may not contain a body.
            body = json.loads(event.get('body') or '{}')
            product_id = body.get('ProductId')

            # -----------------------------------------------------
            # CASE 1:
            # No ProductId supplied -> delete entire cart
            # -----------------------------------------------------
            if not product_id:

                table.delete_item(
                    Key={'CartId': cart_id}
                )

                return response(
                    200,
                    {
                        'message': 'Cart deleted successfully',
                        'CartId': cart_id,
                        'Items': []
                    }
                )

            # -----------------------------------------------------
            # CASE 2:
            # ProductId supplied -> remove only that product
            # -----------------------------------------------------
            result = table.get_item(
                Key={'CartId': cart_id}
            )

            cart = result.get('Item')

            if not cart:
                return response(
                    404,
                    {'message': 'Cart not found'}
                )

            items = cart.get('Items', [])

            # Remove the requested product
            updated_items = [
                item for item in items
                if item.get('ProductId') != product_id
            ]

            # Nothing was removed
            if len(updated_items) == len(items):
                return response(
                    404,
                    {'message': 'Product not found in cart'}
                )

            # If products remain, update the cart
            if updated_items:

                cart['Items'] = updated_items

                table.put_item(
                    Item=cart
                )

            # If the removed product was the final product,
            # delete the cart record completely
            else:

                table.delete_item(
                    Key={'CartId': cart_id}
                )

            return response(
                200,
                {
                    'message': 'Product removed from cart',
                    'CartId': cart_id,
                    'Items': updated_items
                }
            )

        # =========================================================
        # Unsupported HTTP method
        # =========================================================
        else:
            return response(
                405,
                {'message': 'Method not allowed'}
            )

    except Exception as e:
        # Write detailed error to CloudWatch logs
        print(f'CartFunction error: {str(e)}')

        return response(
            500,
            {'message': 'Internal server error'}
        )


def response(status_code, body):
    """
    Standard HTTP response returned to API Gateway.
    """
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
