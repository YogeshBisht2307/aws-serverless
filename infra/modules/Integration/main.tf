module "integration_provision" {
  source = "./Provisioning"
  region_name = var.region_name
  s3_signed_url_user_cred_name = var.s3_signed_url_user_cred_name
  bucket_prefix = var.bucket_prefix
}

resource "aws_s3_object" "mobile_api_src_file_upload" {
  bucket   = "${module.integration_provision.application_source_code_bucket}"
  key      = "${var.lambda_layer_zip}"
  source   = "${path.cwd}/../../build/${var.lambda_layer_zip}"
  etag     = filemd5("${path.cwd}/../../build/${var.lambda_layer_zip}")
}

resource "aws_lambda_layer_version" "lambda_layer" {
  layer_name = "ardent-lambda-layer"
  s3_bucket  = "${module.integration_provision.application_source_code_bucket}"
  s3_key     = aws_s3_object.mobile_api_src_file_upload.id

  compatible_runtimes = ["python3.10"]
}


module "utility_services" {
  source = "./UtilityServices"
  stage = var.stage
  application_source_code_bucket = module.integration_provision.application_source_code_bucket
  enterprise_from_email                  = var.enterprise_from_email
  enterprise_app_name                    = var.enterprise_app_name
  notification_handler_zip               = var.notification_handler_zip
  assets_bucket_name                     = module.integration_provision.assets_bucket_name
  web_panel_base_url                     = var.web_panel_base_url
  secrets_utility_handler_zip            = var.secrets_utility_handler_zip
  mail_handler_zip                       = var.mail_handler_zip
}