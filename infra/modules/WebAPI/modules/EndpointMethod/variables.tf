variable "rest_api_id" {
  description = "Rest API ID"
  type = string
  nullable = false
}

variable "resource_id" {
  description = "Rest API Resource ID"
  type = string
  nullable = false
}

variable "endpoint_method" {
  description = "Rest API Method Type"
  type = string
  nullable = false
}

variable "integrated_lambda_arn" {
  description = "Rest API Method Integration lambda function name"
  type = string
  nullable = false
}


