output "endpoint_method_id" {
  value = aws_api_gateway_method.endpoint_method.id
}

output "endpoint_method_integration_id" {
  value = aws_api_gateway_integration.endpoint_method_integration.id
}
