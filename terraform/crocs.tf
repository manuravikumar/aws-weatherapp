# --- CORS for GET /weather ---
resource "aws_api_gateway_method_response" "weather_method_response" {
  rest_api_id = aws_api_gateway_rest_api.weather_api.id
  resource_id = aws_api_gateway_resource.weather_resource.id
  http_method = aws_api_gateway_method.weather_method.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_integration_response" "weather_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.weather_api.id
  resource_id = aws_api_gateway_resource.weather_resource.id
  http_method = aws_api_gateway_method.weather_method.http_method
  status_code = aws_api_gateway_method_response.weather_method_response.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }

  depends_on = [
    aws_api_gateway_integration.lambda_integration
  ]
}

# --- OPTIONS /weather preflight support ---
resource "aws_api_gateway_method" "weather_options_method" {
  rest_api_id   = aws_api_gateway_rest_api.weather_api.id
  resource_id   = aws_api_gateway_resource.weather_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "weather_options_integration" {
  rest_api_id             = aws_api_gateway_rest_api.weather_api.id
  resource_id             = aws_api_gateway_resource.weather_resource.id
  http_method             = aws_api_gateway_method.weather_options_method.http_method
  type                    = "MOCK"
  integration_http_method = "OPTIONS"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "weather_options_response" {
  rest_api_id = aws_api_gateway_rest_api.weather_api.id
  resource_id = aws_api_gateway_resource.weather_resource.id
  http_method = aws_api_gateway_method.weather_options_method.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "weather_options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.weather_api.id
  resource_id = aws_api_gateway_resource.weather_resource.id
  http_method = aws_api_gateway_method.weather_options_method.http_method
  status_code = aws_api_gateway_method_response.weather_options_response.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# --- Update deployment to include CORS ---
resource "aws_api_gateway_deployment" "weather_deployment" {
  depends_on = [
    aws_api_gateway_integration.lambda_integration,
    aws_api_gateway_integration_response.weather_integration_response,
    aws_api_gateway_integration.weather_options_integration,
    aws_api_gateway_integration_response.weather_options_integration_response
  ]

  rest_api_id = aws_api_gateway_rest_api.weather_api.id
  description = "Deployment for Weather API"
}
