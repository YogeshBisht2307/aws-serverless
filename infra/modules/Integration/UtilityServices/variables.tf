
variable "application_source_code_bucket" {
  type = string
  description = "Application source code bucket name"
}

variable "notification_function_name" {
  type = string
  description = "Mail Send Lambda Function Name"
  default = "notification-handler"
}


variable "secret_manager_lambda_function_name"{
  type = string
  description = "Secret Manager lambda function name"
  default = "secrets-utility"
}

variable "mail_sender_lambda_function_name" {
  type = string
  description = "Secret Manager lambda function name"
  default = "mail-handler"
}

variable "stage"{
    type        = string
    description = "Stage environment of the application"
}

variable "assets_bucket_name" {
  type = string
  description = "Assest bucket name"
}


variable "secrets_utility_handler_zip" {
  type = string
  description = "Secret Utitliy Lambda Handler zip file"
  nullable = false
}

variable "notification_handler_zip" {
  type = string
  description = "App Notification Lambda Handler Zip file"
  nullable = false
}

variable "mail_handler_zip" {
  type = string
  description = "Mail Handler Zip file"
  nullable = false
}


variable "enterprise_app_name" {
  type = string
  description = "Application name for email and SMS"
  nullable = false
}

variable "enterprise_from_email" {
  type = string
  description = "Email for from email of the application"
  nullable = false
}

variable "web_panel_base_url" {
  type = string
  description = "Web Panel base url for sending link email"
}