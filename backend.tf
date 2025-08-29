terraform {
  backend "s3" {
    bucket         = "ayoub-t"   # S3 bucket name
    key            = "global/s3/terraform.tfstate" # Path inside bucket
    region         = "ca-central-1"
    dynamodb_table = "terraform-locks"             # DynamoDB for state locking
    encrypt        = true                          # Encrypt state at rest
  }
}
