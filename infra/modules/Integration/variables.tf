variable "stage" {
  type = string
  description = "Stage of the application"
}

variable "region_name" {
  type = string
  description = "Region name of the application"
}

variable "postgresql_subnet_id" {
  type = string
  description = "Subnet ID of postgresql database instance"
}

variable "lambda_postgres_access_sg" {
  type = string
  description = "Security Group to acess postgres database"
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


variable "s3_signed_url_user_cred_name" {
  type = string
  description = "S3 Signed Url Generator User"
  nullable = false
}

variable "lambda_layer_zip" {
  type        = string
  description = "Name of security group for vpc endpoint"
  nullable  = false
}

variable "bucket_prefix" {
  type        = string
  description = "Bucket name prefix"
  nullable  = false
}