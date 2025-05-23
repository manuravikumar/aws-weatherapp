terraform {
  backend "s3" {
    bucket         = "myterraformstate"
    key            = "weather-api/terraform.tfstate"
    region         = "ap-southeast-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
