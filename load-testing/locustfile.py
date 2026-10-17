from locust import HttpUser, task, between
import uuid
import random
import os

# ---------------------------------------------------------
# Test-run identifier
# ---------------------------------------------------------
# The identifier is supplied when Locust is started.
#
# Examples:
#   Serverless 400-user test:
#       TEST_RUN=SL-400 locust -f locustfile.py
#
#   EC2 400-user test:
#       TEST_RUN=EC2-400 locust -f locustfile.py
#
# If no identifier is supplied, "TEST" is used.
TEST_RUN = os.getenv("TEST_RUN", "TEST")


class EcommerceUser(HttpUser):

    # Simulated pause between customer journeys
    wait_time = between(1, 2)

    @task
    def ecommerce_journey(self):

        # Generate unique cart and order IDs.
        # TEST_RUN allows records from individual
        # experimental runs to be identified later.
        cart_id = f"{TEST_RUN}-CART-{uuid.uuid4()}"
        order_id = f"{TEST_RUN}-ORDER-{uuid.uuid4()}"

        # Randomly select one of the five products
        product_id = random.choice(
            ["P001", "P002", "P003", "P004", "P005"]
        )

        # -------------------------------------------------
        # 1. Browse products
        # -------------------------------------------------
        self.client.get(
            "/products",
            name="GET /products"
        )

        # -------------------------------------------------
        # 2. Add one product to the shopping cart
        # -------------------------------------------------
        self.client.post(
            "/cart",
            json={
                "CartId": cart_id,
                "ProductId": product_id,
                "Quantity": 1
            },
            name="POST /cart"
        )

        # -------------------------------------------------
        # 3. Retrieve the shopping cart
        # -------------------------------------------------
        self.client.get(
            f"/cart/{cart_id}",
            name="GET /cart/{id}"
        )

        # -------------------------------------------------
        # 4. Create the order
        # -------------------------------------------------
        self.client.post(
            "/orders",
            json={
                "OrderId": order_id,
                "CartId": cart_id
            },
            name="POST /orders"
        )

