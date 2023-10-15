
resource "aws_s3_bucket" "assets_bucket" {
  bucket = "${var.region_name}.com.${var.bucket_prefix}.app-assets"

  tags = {
    Name        = "Developer"
    Environment = "IoTfy"
  }
}


resource "aws_s3_bucket_cors_configuration" "assets_bucket_cors_policy" {
  bucket = aws_s3_bucket.assets_bucket.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "POST", "GET"]
    allowed_origins = ["*"]
    expose_headers  = []
  }
}


resource "aws_s3_bucket_public_access_block" "iot_assets_public_access" {
  bucket = aws_s3_bucket.assets_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "allow_public_get_object_access" {
  bucket = aws_s3_bucket.assets_bucket.id

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "AllowGetObject",
        "Effect": "Allow",
        "Principal": "*",
        "Action": ["s3:GetObject"],
        "Resource": ["arn:aws:s3:::${aws_s3_bucket.assets_bucket.id}/*"]
      }
    ]
  })
}


resource "aws_s3_bucket" "application_source_code" {
  bucket = "${var.region_name}.com.${var.bucket_prefix}.application-code"

  tags = {
    Name        = "Developer"
    Environment = "IoTfy"
  }
}


#############################################
######### Create S3 Signed Url Generator User ###############

resource "aws_iam_user" "s3_signed_url_generator_user" {
  name = var.s3_signed_url_generator_user_name

  tags = {
    Developer = "IoTfy"
  }
}

resource "aws_iam_access_key" "s3_signed_url_generator_user_access" {
  user = aws_iam_user.s3_signed_url_generator_user.name
}

data "aws_iam_policy_document" "s3_signed_url_generator_user_access_document" {
  statement {
    effect    = "Allow"
    actions   = [
      "s3:GetObject",
      "s3:GetObjectVersion"
    ]
    resources = ["*"]
  }
}

resource "aws_secretsmanager_secret_version" "s3_signed_url_user_cred" {
  secret_id     = var.s3_signed_url_user_cred_name
  secret_string = jsonencode({
    accessKey = aws_iam_access_key.s3_signed_url_generator_user_access.id
    secretKey = aws_iam_access_key.s3_signed_url_generator_user_access.secret
  })
}