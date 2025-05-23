terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"
    key            = "serverless-weatherapp/terraform.tfstate"
    region         = "ap-southeast-2"
    dynamodb_table = "terraform-locks"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-2"
}

resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "weather_function" {
  filename         = "lambda.zip"
  function_name    = "weather-function"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  source_code_hash = filebase64sha256("lambda.zip")
}

resource "aws_api_gateway_rest_api" "weather_api" {
  name        = "WeatherAPI"
  description = "API for weather data"
}

resource "aws_api_gateway_resource" "weather_resource" {
  rest_api_id = aws_api_gateway_rest_api.weather_api.id
  parent_id   = aws_api_gateway_rest_api.weather_api.root_resource_id
  path_part   = "weather"
}

resource "aws_api_gateway_method" "weather_method" {
  rest_api_id   = aws_api_gateway_rest_api.weather_api.id
  resource_id   = aws_api_gateway_resource.weather_resource.id
  http_method   = "GET"
  authorization = "NONE"
  api_key_required = true
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.weather_api.id
  resource_id             = aws_api_gateway_resource.weather_resource.id
  http_method             = aws_api_gateway_method.weather_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.weather_function.invoke_arn
}

resource "aws_lambda_permission" "api_gateway_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.weather_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.weather_api.execution_arn}/*/*"
}

resource "aws_api_gateway_deployment" "weather_deployment" {
  depends_on = [aws_api_gateway_integration.lambda_integration]
  rest_api_id = aws_api_gateway_rest_api.weather_api.id
  stage_name  = "prod"
}

resource "aws_api_gateway_usage_plan" "weather_plan" {
  name = "weather-usage-plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.weather_api.id
    stage  = aws_api_gateway_deployment.weather_deployment.stage_name
  }

  throttle {
    rate_limit = 10
    burst_limit = 2
  }
}

resource "aws_api_gateway_api_key" "weather_key" {
  name    = "weather-key"
  enabled = true
}

resource "aws_api_gateway_usage_plan_key" "weather_key_attachment" {
  key_id        = aws_api_gateway_api_key.weather_key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.weather_plan.id
}

resource "aws_cloudfront_distribution" "weather_cf" {
  origin {
    domain_name = "${aws_api_gateway_rest_api.weather_api.id}.execute-api.ap-southeast-2.amazonaws.com"
    origin_id   = "apigw-origin"

    custom_origin_config {
      origin_protocol_policy = "https-only"
      http_port              = 80
      https_port             = 443
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled             = true
  default_root_object = ""

  default_cache_behavior {
    target_origin_id       = "apigw-origin"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = true
      cookies {
        forward = "none"
      }
    }

    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
