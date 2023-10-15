output "cors_method_id" {
  value = aws_api_gateway_method.cors_method.id
}

output "cors_method_integration_id" {
  value = aws_api_gateway_integration.cors_method_integration.id
}
