locals {
  databases = {
    clientes = {
      identifier = "soat13-tc-revenda-clientes"
      name       = "clientes_db"
    }
    veiculos = {
      identifier = "soat13-tc-revenda-veiculos"
      name       = "veiculos_db"
    }
    vendas = {
      identifier = "soat13-tc-revenda-vendas"
      name       = "vendas_db"
    }
  }
}

data "aws_vpc" "k8s" {
  filter {
    name   = "tag:Name"
    values = ["soat13-tc-revenda-vpc"]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.k8s.id]
  }

  filter {
    name   = "tag:Name"
    values = ["soat13-tc-revenda-vpc-private-*"]
  }
}

data "aws_security_group" "eks_nodes" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.k8s.id]
  }

  filter {
    name   = "tag:Name"
    values = ["soat13-tc-revenda-node"]
  }
}

resource "aws_security_group" "rds" {
  name        = "soat13-tc-revenda-rds"
  description = "MySQL access from the EKS worker nodes only"
  vpc_id      = data.aws_vpc.k8s.id

  ingress {
    description     = "MySQL from EKS worker nodes"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [data.aws_security_group.eks_nodes.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Project = "soat13-tc-revenda"
  }
}

resource "aws_db_subnet_group" "main" {
  name       = "soat13-tc-revenda-db"
  subnet_ids = data.aws_subnets.private.ids

  tags = {
    Project = "soat13-tc-revenda"
  }
}

resource "aws_db_instance" "service" {
  for_each = local.databases

  identifier                      = each.value.identifier
  engine                          = "mysql"
  engine_version                  = "8.0"
  instance_class                  = var.instance_class
  allocated_storage               = var.allocated_storage_gib
  max_allocated_storage           = var.allocated_storage_gib * 2
  storage_type                    = "gp3"
  storage_encrypted               = true
  db_name                         = each.value.name
  username                        = var.master_username
  manage_master_user_password     = true
  port                            = 3306
  publicly_accessible             = false
  multi_az                        = false
  backup_retention_period         = var.backup_retention_days
  auto_minor_version_upgrade      = true
  deletion_protection             = true
  skip_final_snapshot             = false
  final_snapshot_identifier       = "${each.value.identifier}-final"
  apply_immediately               = false
  db_subnet_group_name            = aws_db_subnet_group.main.name
  vpc_security_group_ids          = [aws_security_group.rds.id]
  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]

  tags = {
    Name    = each.value.identifier
    Project = "soat13-tc-revenda"
    Service = each.key
  }
}

output "db_hosts" {
  description = "Private RDS hostnames by microservice."
  value       = { for service, instance in aws_db_instance.service : service => instance.address }
}

output "db_names" {
  description = "Database names by microservice."
  value       = { for service, instance in aws_db_instance.service : service => instance.db_name }
}

output "db_master_secret_arns" {
  description = "RDS-managed Secrets Manager ARNs for the generated database master credentials."
  value       = { for service, instance in aws_db_instance.service : service => instance.master_user_secret[0].secret_arn }
}
