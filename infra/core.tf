
resource "aws_security_group" "security_group_for_psql_web_lambda" {
  name                = "web-${var.postgres_lambda_access_sg_name}"
  description         = "Security Group for Web api Lambda to access postgresql db"
  vpc_id              = var.vpc_id
  egress {
      protocol = "tcp"
      from_port = 0
      to_port = 65535
      cidr_blocks  = ["0.0.0.0/0"]
  }

  tags                = {
    Developer         = "Iotfy"
  }

}


data "aws_secretsmanager_secret_version" "postgresql_db_creds" {
  secret_id = var.postgresql_db_creds_name
}


resource "aws_secretsmanager_secret_version" "postgresql_db_creds" {
  secret_id     = var.postgresql_db_creds_name
  secret_string = jsonencode({
    ip     = module.databases.postgresql_server_private_ip,
    username = jsondecode(data.aws_secretsmanager_secret_version.postgresql_db_creds.secret_string)["username"],
    password = jsondecode(data.aws_secretsmanager_secret_version.postgresql_db_creds.secret_string)["password"],
    port     = jsondecode(data.aws_secretsmanager_secret_version.postgresql_db_creds.secret_string)["port"],
    dbName   = jsondecode(data.aws_secretsmanager_secret_version.postgresql_db_creds.secret_string)["dbName"]
  })
}

resource "aws_security_group" "security_group_for_vpc_endpoint" {
    name              = "${var.vpc_endpoint_security_group_name}"
    description       = "Security Group For VPC Endpoint to allow lambda access outside the VPC"
    vpc_id            = var.vpc_id

    ingress {
     protocol         = "tcp"
     from_port        = 443
     to_port          = 443
     security_groups  = [
      aws_security_group.security_group_for_psql_web_lambda.id
     ]
    }

    egress {
      protocol = "tcp"
      from_port = 0
      to_port = 65535
      cidr_blocks  = ["0.0.0.0/0"]
    }

    tags = {
        Developer = "Iotfy"
    }
}


