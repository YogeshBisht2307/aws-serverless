terraform{
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 5.0"
        }
        archive = {
            source  = "hashicorp/archive"
            version = "~> 2.4.0"
        }
    }
}

provider "aws" {
    region = var.region
}


module "databases" {
  source = "./modules/Database"
  database_user                     = jsondecode(data.aws_secretsmanager_secret_version.postgresql_db_creds.secret_string)["username"]
  database_name                     = jsondecode(data.aws_secretsmanager_secret_version.postgresql_db_creds.secret_string)["dbName"]
  database_password                 = jsondecode(data.aws_secretsmanager_secret_version.postgresql_db_creds.secret_string)["password"]
  database_port                     = tonumber(jsondecode(data.aws_secretsmanager_secret_version.postgresql_db_creds.secret_string)["port"])
  vpc_id                            = var.vpc_id
  vpc_cidr                          = var.vpc_cidr
  stage                             = var.stage
  postgresql_subnet_id              = var.postgresql_subnet_id
  availability_zone                 = var.postgresql_availability_zone
  web_lambda_postgres_access_sg     = aws_security_group.security_group_for_psql_web_lambda.id
}


module "backend_integration" {
  source = "./modules/Integration"
  stage = var.stage
  region_name = var.region_name
  postgresql_subnet_id = var.postgresql_subnet_id
  lambda_postgres_access_sg = aws_security_group.security_group_for_psql_web_lambda.id
  secrets_utility_handler_zip = var.secrets_utility_handler_zip
  notification_handler_zip = var.notification_handler_zip
  mail_handler_zip = var.mail_handler_zip
  enterprise_app_name = var.enterprise_app_name
  enterprise_from_email = var.enterprise_from_email
  web_panel_base_url = var.web_panel_base_url
  s3_signed_url_user_cred_name = var.s3_signed_url_user_cred_name
  lambda_layer_zip = var.lambda_layer_zip
  bucket_prefix    = var.bucket_prefix
}

module "web_api" {
  source                                 = "./modules/WebAPI"
  region                                 = var.region
  account_id                             = var.account_id 
  stage                                  = var.stage
  vpc_id                                 = var.vpc_id
  vpc_cidr                               = var.vpc_cidr
  postgresql_subnet_id                   = var.postgresql_subnet_id
  lambda_postgres_access_sg              = aws_security_group.security_group_for_psql_web_lambda.id
  application_source_code_bucket         = module.backend_integration.application_source_code_bucket
  assets_bucket                          = module.backend_integration.assets_bucket_name
  web_api_handler_zip                    = var.web_api_handler_zip
  mail_handler_arn                       = module.backend_integration.mail_handler_arn
  secret_handler_arn                     = module.backend_integration.secret_handler_arn
  lambda_layer_arn                       = module.backend_integration.lambda_layer_arn
}
