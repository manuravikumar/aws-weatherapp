output "cloudfront_domain" {
  value = aws_cloudfront_distribution.weather_cf.domain_name
}

output "api_key" {
  value = aws_api_gateway_api_key.weather_key.value
  sensitive = true
}
