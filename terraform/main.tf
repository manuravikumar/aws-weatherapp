resource "aws_iam_role" "lambda_exec" {
  name = "lambda-exec-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy_attachment" "lambda_logs" {
  name       = "lambda_logs"
  roles      = [aws_iam_role.lambda_exec.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "weather_function" {
  function_name = var.lambda_function_name
  runtime       = "python3.12"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "weather_handler.lambda_handler"
  filename      = "lambda.zip"
  source_code_hash = filebase64sha256("lambda.zip")

  environment {
    variables = {
      WEATHER_API_KEY = var.weather_api_key
    }
  }
}

resource "aws_api_gateway_rest_api" "weather_api" {
  name        = var.api_gateway_name
  description = "Weather Forecast API"
}

resource "aws_api_gateway_resource" "weather" {
  rest_api_id = aws_api_gateway_rest_api.weather_api.id
  parent_id   = aws_api_gateway_rest_api.weather_api.root_resource_id
  path_part   = "weather"
}

resource "aws_api_gateway_method" "get_weather" {
  rest_api_id   = aws_api_gateway_rest_api.weather_api.id
  resource_id   = aws_api_gateway_resource.weather.id
  http_method   = "GET"
  authorization = "NONE"
  api_key_required = true
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id             = aws_api_gateway_rest_api.weather_api.id
  resource_id             = aws_api_gateway_resource.weather.id
  http_method             = aws_api_gateway_method.get_weather.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.weather_function.invoke_arn
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.weather_function.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.weather_api.execution_arn}/*/*"
}

resource "aws_api_gateway_deployment" "weather_api" {
  depends_on = [aws_api_gateway_integration.lambda]
  rest_api_id = aws_api_gateway_rest_api.weather_api.id
  stage_name  = "prod"
}

resource "aws_api_gateway_api_key" "weather_key" {
  name        = "weather-api-key"
  enabled     = true
  stage_key {
    rest_api_id = aws_api_gateway_rest_api.weather_api.id
    stage_name  = aws_api_gateway_deployment.weather_api.stage_name
  }
}

resource "aws_cloudfront_distribution" "weather_cf" {
  origin {
    domain_name = "${aws_api_gateway_rest_api.weather_api.execution_arn}.execute-api.ap-southeast-2.amazonaws.com"
    origin_id   = "weather-api"
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled             = true
  default_root_object = ""
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "weather-api"

    forwarded_values {
      query_string = true
      headers      = ["Accept"]
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
