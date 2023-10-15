# Resource : auth
resource "aws_api_gateway_resource" "admin_auth_resource" {
  rest_api_id = aws_api_gateway_rest_api.web_rest_api.id
  parent_id   = aws_api_gateway_resource.web_api_admin_resource.id
  path_part   = "auth"
}

# Resource : auth/login
resource "aws_api_gateway_resource" "admin_auth_login_resource" {
  rest_api_id = aws_api_gateway_rest_api.web_rest_api.id
  parent_id   = aws_api_gateway_resource.admin_auth_resource.id
  path_part   = "login"
}

# Resource : auth/login [POST]
module "admin_auth_login_method" {
  source            = "./modules/EndpointMethod"
  rest_api_id        = aws_api_gateway_rest_api.web_rest_api.id
  resource_id       = aws_api_gateway_resource.admin_auth_login_resource.id
  endpoint_method   = "POST"
  integrated_lambda_arn = aws_lambda_function.web_api_lambda_handler.invoke_arn
}

module "admin_auth_login_resource_cors" {
  source            = "./modules/EndpointCors"
  rest_api_id        = aws_api_gateway_rest_api.web_rest_api.id
  resource_id       = aws_api_gateway_resource.admin_auth_login_resource.id
}
