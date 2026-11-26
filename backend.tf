terraform {
  backend "s3" {
    bucket       = "obiom-msc-ecommerce-terraform-state"
    key          = "ecommerce/terraform.tfstate"
    region       = "eu-west-2"
    encrypt      = true
    use_lockfile = true
  }
}