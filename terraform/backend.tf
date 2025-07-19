terraform {
  backend "s3" {
    bucket         = "terraform-state-bucket-caprover"
    key            = "shortlink-app/terraform.tfstate"
    region         = "eu-north-1"
    dynamodb_table = "terraform-lock-table"
    encrypt        = true
  }
}