variable "volume_size" {
    type = number
    description = "Size of the ebs volume"
    default = 50
}

variable "postgresql_ebs_volume_name" {
    type = string
    description = "Name of postgresql ebs volume"
    default = "PostgresqlDBVolume"
}

variable "ec2_server_name" {
    type = string
    description = "Name of Postgresql Database Server"
    default = "PostgresqlDBServer"
}

variable "instance_access_sg_name" {
    type = string
    description = "Name of security group for ec2"
    default = "PostgresqlAccessSG"
}

variable "ami_id" {
    type = string
    description = "aws instance ami id "
    default = "ami-0cee553502aa532a2"
}

variable "instance_type" {
  type = string
  description = "ec2 instance type"
  default = "t4g.small"
}


variable "vpc_id" {
    type = string
    description = "VPC Id in which instance will be deployed"
}


variable "database_user"{
    type = string
    description = "Username of postgresql database"
}

variable "database_password"{
    type = string
    description = "Password of postgresql database"
}

variable "database_name"{
    type = string
    description = "Name of postgresql database"
}


variable "postgresql_subnet_id" {
    type = string
    description = "Subnet ID for instance"
}

variable "vpc_cidr" {
    type = string
    description = "Cidr value for postgresql"
}

variable "postgresql_keypair" {
    type = string
    default = "PostgresqlServerKeyPair"
}

variable "stage" {
  type          = string
  description   = "Application Server Stage"  
}

variable "availability_zone" {
    type   = string
    default = "ap-south-1b"
}

variable "web_lambda_postgres_access_sg" {
  type = string
  description = "Security group to provide postgresql database access for admin lambda"
}

variable "database_port" {
  type = string
  description = "Database port value"
}