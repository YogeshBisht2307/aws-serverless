
output "database_user"{
  value = var.database_user
}

output "database_pass"{
  value = var.database_password
}

output "database_name"{
  value = var.database_name
}


output "postgresql_server_private_ip" {
  value = aws_instance.ec2_server_instance.private_ip
}

output "postgresql_server_public_dns" {
  value = aws_instance.ec2_server_instance.public_dns
}