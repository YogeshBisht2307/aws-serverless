output "mail_handler_arn" {
  value = module.utility_services.mail_handler_arn
}

output "secret_handler_arn" {
    value = module.utility_services.secret_handler_arn
}

output "notification_handler_arn" {
    value = module.utility_services.notification_handler_arn
}

output "application_source_code_bucket" {
  value = module.integration_provision.application_source_code_bucket
}

output "assets_bucket_name" {
  value = module.integration_provision.assets_bucket_name
}

output "lambda_layer_arn" {
  value = aws_lambda_layer_version.lambda_layer.arn
}