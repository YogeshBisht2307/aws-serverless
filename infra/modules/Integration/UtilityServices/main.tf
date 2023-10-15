resource "aws_s3_object" "secret_manager_file_upload" {
 bucket = "${var.application_source_code_bucket}"
 key = "${var.secrets_utility_handler_zip}"
 source       = "${path.cwd}/../../build/${var.secrets_utility_handler_zip}"
 etag         = filemd5("${path.cwd}/../../build/${var.secrets_utility_handler_zip}")
}

resource "aws_s3_object" "notification_handler_file_upload" {
 bucket = "${var.application_source_code_bucket}"
 key = "${var.notification_handler_zip}"
 source       = "${path.cwd}/../../build/${var.notification_handler_zip}"
 etag         = filemd5("${path.cwd}/../../build/${var.notification_handler_zip}")
}

resource "aws_s3_object" "mail_source_file_upload" {
 bucket = "${var.application_source_code_bucket}"
 key = "${var.secrets_utility_handler_zip}"
 source = "${path.cwd}/../../build/${var.secrets_utility_handler_zip}"
 etag = filemd5("${path.cwd}/../../build/${var.secrets_utility_handler_zip}")
}



# Secret Manager Utitlity Lambda

resource "aws_iam_role" "secret_manager_lambda_access_role" {
  name               = "${var.secret_manager_lambda_function_name}-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "lambda.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  })

  inline_policy {
    name   = "SecretManagerLambdaAccessPolicy"
    policy = jsonencode({
      "Version": "2012-10-17",
      "Statement":[{
          "Effect":"Allow",
          "Action": ["logs:CreateLogGroup"]
          "Resource": ["*"]
        },
        {
          "Effect":"Allow",
          "Action": [
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ]
          "Resource": ["*"]
        },
        {
          Effect = "Allow"
          Action = [
            "secretsmanager:GetSecretValue",
            "secretsmanager:DescribeSecret",
            "secretsmanager:CreateSecret",
            "secretsmanager:ListSecrets"
          ]
          Resource = ["*"]
        }
      ]
    })
  }
}

resource "aws_lambda_function" "secret_manager_lambda_handler" {
  s3_bucket        = "${var.application_source_code_bucket}"
  s3_key           = aws_s3_object.secret_manager_file_upload.id
  function_name    = "${var.secret_manager_lambda_function_name}"
  runtime          = "python3.10"
  handler          = "src.app.request_handler"
  source_code_hash = filemd5("${path.cwd}/../../build/${var.secrets_utility_handler_zip}")
  role             = aws_iam_role.secret_manager_lambda_access_role.arn
  timeout          = 60
  memory_size      = 512

  environment {
    variables = {
      STAGE = var.stage
    }
  }

  ephemeral_storage {
    size = 512
  }

  tags = {
      Developer = "IoTfy"
   }

  depends_on = [
    aws_s3_object.secret_manager_file_upload
  ]
}

resource "aws_cloudwatch_log_group" "secret_manager_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.secret_manager_lambda_handler.function_name}"
  retention_in_days = 5
}


# Notification Utitlity Lambda
resource "aws_iam_role" "notification_lambda_handler_execution_role" {
  name               = "${var.notification_function_name}-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "lambda.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  })

  inline_policy {
    name   = "AwsIoTLambdHandlerAccessPolicy"
    policy = jsonencode({
      "Version": "2012-10-17",
      "Statement":[{
          "Effect":"Allow",
          "Action": ["logs:CreateLogGroup"]
          "Resource": ["*"]
        },
        {
          "Effect":"Allow",
          "Action": [
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ]
          "Resource": ["*"]
        },
        {
          Effect = "Allow"
          Action = [
            "sns:CreatePlatformEndpoint",
            "sns:DeleteEndpoint",
            "sns:Publish"
          ]
          Resource = ["*"]
        }
      ]
    })
  }
}

resource "aws_lambda_function" "notification_handler" {
  s3_bucket        = "${var.application_source_code_bucket}"
  s3_key           = aws_s3_object.notification_handler_file_upload.id
  function_name    = "${var.notification_function_name}"
  runtime          = "python3.10"
  handler          = "src.app.request_handler"
  source_code_hash = filemd5("${path.cwd}/../../build/${var.notification_handler_zip}")
  role             = aws_iam_role.notification_lambda_handler_execution_role.arn
  timeout           = 60

  ephemeral_storage {
    size = 512
  }

  memory_size = 512

  environment {
    variables = {
      STAGE = var.stage
    }
  }

  tags = {
      Developer = "IoTfy"
  }

  depends_on = [
    aws_s3_object.notification_handler_file_upload
  ]
}

resource "aws_cloudwatch_log_group" "notification_handler_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.notification_handler.function_name}"
  retention_in_days = 5
}


# Mail Sender Utitlity Lambda

resource "aws_iam_role" "mail_sender_lambda_service_role" {
  name               = "${var.mail_sender_lambda_function_name}-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "lambda.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  })

  inline_policy {
    name   = "RuleEngineServiceExecutionPolicy"
    policy = jsonencode({
      "Version": "2012-10-17",
      "Statement":[{
          "Effect":"Allow",
          "Action": ["logs:CreateLogGroup"]
          "Resource": ["*"]
        },
        {
          "Effect":"Allow",
          "Action": [
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ]
          "Resource": ["*"]
        },
        {
          Effect = "Allow"
          Action = [
            "secretsmanager:GetSecretValue",
            "secretsmanager:DescribeSecret",
            "secretsmanager:CreateSecret",
            "secretsmanager:ListSecrets"
          ]
          Resource = ["*"]
        }
      ]
    })
  }
}

resource "aws_lambda_function" "mail_sender_handler" {
  s3_bucket        = "${var.application_source_code_bucket}"
  s3_key           = "${aws_s3_object.mail_source_file_upload.id}"
  function_name    = "${var.mail_sender_lambda_function_name}"
  runtime          = "python3.10"
  handler          = "src.main.request_handler"
  source_code_hash = filemd5("${path.cwd}/../../build/${var.mail_handler_zip}")
  role             = aws_iam_role.mail_sender_lambda_service_role.arn
  timeout          = 60
  ephemeral_storage {
    size = 512
  }

  memory_size = 512

  environment {
    variables = {
      STAGE = var.stage
      ASSETS_BUCKET_NAME = var.assets_bucket_name
      CRADLE_FROM_EMAIL = var.enterprise_from_email
      CRADLE_APP_NAME = var.enterprise_app_name
      ADMIN_PANEL_BASE_URL = var.web_panel_base_url
    }
  }

  tags = {
      Developer = "IoTfy"
  }

  depends_on = [
    aws_s3_object.mail_source_file_upload
  ]
}

resource "aws_cloudwatch_log_group" "mail_sender_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.mail_sender_handler.function_name}"
  retention_in_days = 5
}
