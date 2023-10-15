output "mail_handler_arn" {
  value = aws_lambda_function.mail_sender_handler.arn
}

output "secret_handler_arn" {
    value = aws_lambda_function.secret_manager_lambda_handler.arn
}

output "notification_handler_arn" {
    value = aws_lambda_function.notification_handler.arn
}
