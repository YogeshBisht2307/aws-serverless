resource "aws_api_gateway_rest_api" "web_rest_api" {
  name = var.web_rest_api_name
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_method_settings" "api_logging_enabled" {
  rest_api_id = aws_api_gateway_rest_api.web_rest_api.id
  stage_name  = var.stage
  method_path = "*/*"

  settings {
    metrics_enabled = true
    logging_level   = "INFO"
    data_trace_enabled = true
  }
}

resource "aws_api_gateway_resource" "web_api_admin_resource" {
  rest_api_id = aws_api_gateway_rest_api.web_rest_api.id
  parent_id   = aws_api_gateway_rest_api.web_rest_api.root_resource_id
  path_part   = "admin"
}

resource "aws_s3_object" "web_apis_handle_file_upload" {
  bucket = var.application_source_code_bucket
  key    = var.web_api_handler_zip
  source = "${path.cwd}/../../build/${var.web_api_handler_zip}"
  etag   = filemd5("${path.cwd}/../../build/${var.web_api_handler_zip}")
}



resource "aws_api_gateway_deployment" "rest_api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.web_rest_api.id
  stage_name  = var.stage
  triggers    = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.admin_auth_resource.id,
      aws_api_gateway_resource.admin_auth_login_resource.id,
      module.admin_auth_login_method.endpoint_method_id,
      module.admin_auth_login_method.endpoint_method_integration_id,
      module.admin_auth_login_resource_cors.cors_method_id,
      module.admin_auth_login_resource_cors.cors_method_integration_id
    ])
  )}

  lifecycle {
    create_before_destroy = true
  }

}

