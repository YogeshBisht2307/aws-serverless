variable "account_id"{
  type        = string
  description = "The account ID in which to create/manage resources"
  nullable    = false
}

variable "region" {
    type        = string
    description = "The region in which to create/manage resources"
    nullable    = false
}

variable "region_name" {
    type        = string
    description = "The region in which to create/manage resources"
    nullable    = false
}

variable "stage" {
  type        = string
  description = "Application Server Stage"
  nullable    = false
  validation {
    condition     = length(var.stage) <= 4 && contains(["prod", "test", "dev"], var.stage)
    error_message = "The stage value must be a one of ['prod', 'test', 'dev']"
  }
}

variable "vpc_id" {
  type = string
  description = "VPC id in which database server and lambda will be be deployed"
  nullable    = false
  validation {
    condition     = length(var.vpc_id) > 4 && substr(var.vpc_id, 0, 4) == "vpc-"
    error_message = "The vpc id value must be a valid vpc id, starting with \"vpc-\"."
  }
}

variable "vpc_cidr" {
  type  = string
  description = "VPC CIDR in which database server and lambda will be be deployed"
  nullable    = false
}



variable "postgresql_subnet_id" {
  type = string
  description = "VPC Subnet ID in which postgresql database server will be be deployed"
  nullable    = false
  validation {
    condition     = length(var.postgresql_subnet_id) > 7 && substr(var.postgresql_subnet_id, 0, 7) == "subnet-"
    error_message = "The subnet id value must be a valid subnet id, starting with \"subnet-\"."
  }
}


variable "postgresql_availability_zone" {
  type = string
  description = "Availability Zone in which postgresql db will be deployed"
  nullable    = false
}


variable "postgresql_db_creds_name" {
  type = string
  description = "Secret name for postgresql database"
  nullable = false
}


variable "notification_handler_zip" {
  type = string
  description = "Notification handler zip file"
  nullable = false
}

variable "secrets_utility_handler_zip" {
  type = string
  description = "secret utility handler zip file"
  nullable = false
}

variable "web_api_handler_zip" {
  type = string
  description = "web api handler zip file"
  nullable = false
}

variable "mail_handler_zip" {
  type = string
  description = "Mail handler zip file"
  nullable = false
}

variable "enterprise_app_name" {
  type = string
  description = "Enterprise app name"
  nullable = false
}

variable "enterprise_from_email" {
  type = string
  description = "Enterpise from email for email services"
  nullable = false
}

variable "web_panel_base_url" {
   type = string
   description = "Enterprise web application base url"
   nullable = false
}

variable "s3_signed_url_user_cred_name" {
    type        = string
    description = "Signed url user creds"
    nullable = false
}

variable "postgres_lambda_access_sg_name" {
  type = string
  description = "Mame of security group for postgresql lambda "
  default = "postgresql-access-sg-for-lambda"
}

variable "vpc_endpoint_security_group_name" {
    type        = string
    description = "Name of security group for vpc endpoint"
    default     = "lambda-access-vpc-endpoint-sg"
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