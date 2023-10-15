
variable "region_name" {
    type        = string
    description = "The region in which to create/manage resources"
    nullable    = false
}


variable "s3_signed_url_user_cred_name" {
    type        = string
    description = "Signed url user creds"
    nullable = false
}


variable "s3_signed_url_generator_user_name" {
    type        = string
    description = "Signed url user creds"
    default = "S3SignedUrlGenerator"
}

variable "bucket_prefix" {
  type        = string
  description = "Bucket name prefix"
  nullable  = false
}
