provider "aws" {
  region = "ca-central-1"
}

resource "aws_s3_bucket" "example" {
  bucket = "hyperbucket2bouagna"
  
}

