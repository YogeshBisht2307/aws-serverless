output "application_source_code_bucket" {
  value = aws_s3_bucket.application_source_code.id
}

output "assets_bucket_name" {
  value = aws_s3_bucket.assets_bucket.id
}