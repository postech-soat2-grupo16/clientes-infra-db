provider "aws" {
  region = var.aws_region
}

#Configuração do Terraform State
terraform {
  backend "s3" {
    bucket = "terraform-state-soat"
    key    = "rds-clientes-db/terraform.tfstate"
    region = "us-east-1"

    dynamodb_table = "terraform-state-soat-locking"
    encrypt        = true
  }
}

#Security Group DB
resource "aws_security_group" "security_group_db_clientes" {
  name_prefix = "security-group-clientes-db"
  description = "SG RDS - Clientes"
  vpc_id      = var.vpc_soat

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.security_group_load_balancer]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    infra   = "vpc-soat"
    Name    = "security-group-clientes-db"
    service = "clientes"
  }
}

# DB Subnet group
resource "aws_db_subnet_group" "db_rds_subnet_group_clientes" {
  name = "subnet-group-clientes-db"
  subnet_ids = [
    var.subnet_a_id,
    var.subnet_b_id
  ]

  tags = {
    Name    = "DB Subnet Group - Clientes"
    infra   = "subnet-group-clientes"
    service = "clientes"
  }
}

resource "aws_db_instance" "postgresql_clientes_db" {
  identifier             = "clientes"
  allocated_storage      = 20
  db_name                = "clientes"
  engine                 = "postgres"
  engine_version         = "15.3"
  instance_class         = "db.t3.micro"
  skip_final_snapshot    = true
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.db_rds_subnet_group_clientes.name
  vpc_security_group_ids = [aws_security_group.security_group_db_clientes.id]

  tags = {
    Name    = "clientes-db"
    infra   = "clientes-db"
    service = "clientes"
  }
}
