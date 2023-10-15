resource "aws_ebs_volume" "ebs_volume" {
    type              = "gp2"
    availability_zone = var.availability_zone
    size              = var.volume_size
    tags              = {
        Name          = "${var.postgresql_ebs_volume_name}"
        Developer     = "Iotfy"
    }
}

resource "aws_security_group" "security_group_for_ec2" {
    name              = "${var.instance_access_sg_name}"
    description       = "Security Group For allow database connection on postgresql server"
    vpc_id            = var.vpc_id

    ingress {
     protocol         = "tcp"
     from_port        = 22
     to_port          = 22
     cidr_blocks      = ["0.0.0.0/0"]
    }

    ingress {
     protocol         = "tcp"
     from_port        = var.database_port
     to_port          = var.database_port
     security_groups  = [var.web_lambda_postgres_access_sg]
    }

    egress {
      protocol = "tcp"
      from_port = 0
      to_port = 65535
      cidr_blocks  = ["0.0.0.0/0"]
    }

    tags              = {
      Developer     = "Iotfy"
    }
}


resource "aws_instance" "ec2_server_instance" {
    ami               = var.ami_id
    availability_zone = var.availability_zone
    monitoring        = false
    source_dest_check = true
    tenancy           = "default"
    instance_type     = var.instance_type
    key_name          = aws_key_pair.key_pair.id
    subnet_id         = var.postgresql_subnet_id
    vpc_security_group_ids   = [aws_security_group.security_group_for_ec2.id]

    credit_specification {
      cpu_credits     = "standard"
    }

    tags = {
      Name            ="${var.ec2_server_name}" 
      Developer       = "IoTfy"
    }

    user_data_base64  =  base64encode(templatefile("${path.module}/init.sh",
        {
        VpcCIDR         = "${var.vpc_cidr}"
        EBSVolumeID     = "${aws_ebs_volume.ebs_volume.id}"
        DatabaseUser    = "${var.database_user}"
        DatabasePassword= "${var.database_password}"
        DatabaseName    = "${var.database_name}"
        DatabasePort    = "${var.database_port}"
        }
    ))
}

resource "aws_volume_attachment" "instance_volume_attachment" {
  device_name = "/dev/sdh"
  volume_id  = aws_ebs_volume.ebs_volume.id
  instance_id = aws_instance.ec2_server_instance.id
}

resource "tls_private_key" "rsa_pk" {
  algorithm       = "RSA"
  rsa_bits        = "4096"
}

resource "aws_key_pair" "key_pair" {
  key_name        = var.postgresql_keypair
  public_key      = tls_private_key.rsa_pk.public_key_openssh
  provisioner "local-exec" {
    command = "echo '${tls_private_key.rsa_pk.private_key_pem}' > ./${var.postgresql_keypair}.pem"
  }
}


