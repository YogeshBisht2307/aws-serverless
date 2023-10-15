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

variable "application_source_code_bucket" {
  type  = string
  description = "application source Code bucket name"
  nullable    = false
}

variable "assets_bucket" {
  type  = string
  description = "mobile app related assets bucket name"
  nullable    = false
}

variable "lambda_postgres_access_sg" {
  type  = string
  description = "Security group for lambda function to access postgresql database"
  nullable    = false
}

variable "web_api_handler_zip" {
  type  = string
  description = "Web API handler zip file name"
  nullable    = false
}

variable "mail_handler_arn" {
  type  = string
  description = "Mail handler lambda Arn"
  nullable    = false
}

variable "secret_handler_arn" {
  type  = string
  description = "Secret handler lambda Arn"
  nullable    = false
}

variable "web_rest_api_name" {
  type  = string
  description = "web rest api name"
  default = "ardent-web-api"
}

variable "lambda_function_name" {
  type = string
  description = "web api handler function name"
  default = "web-api-handler"
}

variable "lambda_layer_arn" {
  type = string
  description = "mobile api handler function name"
  nullable = false
}
