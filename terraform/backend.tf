terraform {
  backend "s3" {
    bucket         = "digit-hcm-terraform-state"
    key            = "environments/${var.environment}/terraform.tfstate"
    region         = "af-south-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}