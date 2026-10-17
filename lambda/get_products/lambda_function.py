
import json
import os
import boto3

from decimal import Decimal
from botocore.config import Config


# DynamoDB configuration
dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(
    os.environ.get("PRODUCTS_TABLE", "Products")
)


# S3 configuration: London region, regional endpoint, and Signature V4
s3 = boto3.client(
    "s3",
    region_name="eu-west-2",
    endpoint_url="https://s3.eu-west-2.amazonaws.com",
    config=Config(signature_version="s3v4")
)

BUCKET_NAME = os.environ["BUCKET_NAME"]


class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        return super().default(obj)


def lambda_handler(event, context):
    try:
        response = table.scan()
        products = response.get("Items", [])

        # Generate temporary signed URLs for product images
        for product in products:
            image_key = product.get("ImageKey")

            if image_key:
                product["ImageUrl"] = s3.generate_presigned_url(
                    ClientMethod="get_object",
                    Params={
                        "Bucket": BUCKET_NAME,
                        "Key": image_key
                    },
                    ExpiresIn=3600,
                    HttpMethod="GET"
                )

        return {
            "statusCode": 200,
            "headers": {
                "Content-Type": "application/json"
            },
            "body": json.dumps(
                products,
                cls=DecimalEncoder
            )
        }

    except Exception as error:
        print(f"GetProducts error: {error}")

        return {
            "statusCode": 500,
            "headers": {
                "Content-Type": "application/json"
            },
            "body": json.dumps({
                "message": "Unable to retrieve products"
            })
        }

