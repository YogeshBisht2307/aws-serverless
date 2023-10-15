resource "aws_iam_role" "web_api_handler_execution_role" {
  name = "${var.lambda_function_name}-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "lambda.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })

  inline_policy {
    name = "LambdaExecutionCloudWatchAccessPolicy"
    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [{
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogGroup"
        ]
        "Resource" : "*"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ]
          "Resource" : "*"
        },
        {
          Effect = "Allow"
          Action = [
            "ec2:CreateNetworkInterface",
            "ec2:DescribeNetworkInterfaces",
            "ec2:DeleteNetworkInterface"
          ]
          Resource = ["*"]
        },
        {
          Effect = "Allow"
          Action = [
            "s3:GetObject",
            "s3:PutObject",
            "s3:GetObjectVersion"
          ]
          Resource = ["*"]
        },
        {
          "Effect" : "Allow"
          "Action" : [
            "lambda:InvokeFunction"
          ]
          "Resource" = "*"
        }
      ]
    })
  }
}

resource "aws_lambda_function" "web_api_lambda_handler" {
  s3_bucket        = var.application_source_code_bucket
  s3_key           = aws_s3_object.web_apis_handle_file_upload.id
  function_name    = var.lambda_function_name
  runtime          = "python3.10"
  handler          = "app.request_handler"
  source_code_hash = filemd5("${path.cwd}/../../build/${var.web_api_handler_zip}")
  role             = aws_iam_role.web_api_handler_execution_role.arn
  timeout          = 30
  memory_size      = 512

  layers           = [var.lambda_layer_arn]

  ephemeral_storage {
    size = 512
  }

  environment {
    variables = {
      STAGE                       = var.stage
      ASSETS_BUCKET_NAME          = var.assets_bucket
      MAIL_HANDLER                = var.mail_handler_arn
      SECRET_HANDLER              = var.secret_handler_arn
    }
  }

  vpc_config {
    subnet_ids         = [var.postgresql_subnet_id]
    security_group_ids = [var.lambda_postgres_access_sg]
  }

  depends_on = [aws_s3_object.web_apis_handle_file_upload]
}

resource "aws_cloudwatch_log_group" "admin_api_handler_lambda_log" {
  name              = "/aws/lambda/${aws_lambda_function.web_api_lambda_handler.function_name}"
  retention_in_days = 5
}


resource "aws_lambda_permission" "web_api_permission_to_invoke_web_api_handler" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.web_api_lambda_handler.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.web_rest_api.execution_arn}/*"
}