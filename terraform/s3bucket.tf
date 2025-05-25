resource "aws_s3_bucket" "frontend" {
  bucket         = "weatherfrontend-bucket"
  force_destroy  = true
}

resource "aws_s3_bucket_public_access_block" "frontend_block" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_website_configuration" "frontend_website" {
  bucket = aws_s3_bucket.frontend.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

resource "aws_s3_bucket_policy" "frontend_policy" {
  depends_on = [aws_s3_bucket_public_access_block.frontend_block]

  bucket = aws_s3_bucket.frontend.id

 policy = jsonencode({
  Version = "2012-10-17",
  Statement = [
    {
      Sid       = "AllowCloudFrontOACReadAccess",
      Effect    = "Allow",
      Principal = {
        Service = "cloudfront.amazonaws.com"
      },
      Action    = "s3:GetObject",
      Resource  = "${aws_s3_bucket.frontend.arn}/*",
      Condition = {
        StringEquals = {
          "AWS:SourceArn" = "arn:aws:cloudfront::864981714330:distribution/E1JJXRQXMWRYB4"
        }
      }
    },
    {
      Sid       = "PublicReadGetObject",
      Effect    = "Allow",
      Principal = "*",
      Action    = "s3:GetObject",
      Resource  = "${aws_s3_bucket.frontend.arn}/*"
    }
  ]
})

}
