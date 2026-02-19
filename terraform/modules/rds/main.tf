# Random password if not provided
resource "random_password" "database" {
  count = var.database_password == null ? 1 : 0
  
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

locals {
  database_password = var.database_password != null ? var.database_password : random_password.database[0].result
}

# Security group for RDS
resource "aws_security_group" "rds" {
  name        = "${var.environment}-rds-sg"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = var.vpc_id
  
  ingress {
    description     = "PostgreSQL from VPC"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    cidr_blocks     = ["10.0.0.0/8"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(var.tags, {
    Name = "${var.environment}-rds-sg"
  })
}

# DB Subnet Group
resource "aws_db_subnet_group" "rds" {
  name       = "${var.environment}-rds-subnet-group"
  subnet_ids = var.private_subnet_ids
  
  tags = merge(var.tags, {
    Name = "${var.environment}-rds-subnet-group"
  })
}

# DB Parameter Group
resource "aws_db_parameter_group" "postgres" {
  name   = "${var.environment}-postgres15-pg"
  family = var.family
  
  parameter {
    name  = "log_connections"
    value = "1"
  }
  
  parameter {
    name  = "log_disconnections"
    value = "1"
  }
  
  parameter {
    name  = "log_duration"
    value = "1"
  }
  
  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }
  
  parameter {
    name  = "shared_preload_libraries"
    value = "pg_stat_statements"
  }
  
  parameter {
    name  = "pg_stat_statements.track"
    value = "all"
  }
  
  tags = var.tags
}

# Primary RDS instance
resource "aws_db_instance" "primary" {
  identifier = "${var.environment}-digit-hcm-postgres"
  
  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class
  
  allocated_storage     = var.allocated_storage
  storage_type          = var.storage_type
  storage_encrypted     = true
  
  db_name  = var.database_name
  username = var.database_username
  password = local.database_password
  
  db_subnet_group_name   = aws_db_subnet_group.rds.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  parameter_group_name   = aws_db_parameter_group.postgres.name
  
  backup_retention_period = var.backup_retention_period
  backup_window          = var.backup_window
  maintenance_window     = var.maintenance_window
  
  multi_az               = var.multi_az
  skip_final_snapshot    = var.skip_final_snapshot
  deletion_protection    = var.deletion_protection
  
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  
  tags = merge(var.tags, {
    Name = "${var.environment}-postgres-primary"
  })
}

# Read Replica - Conditional on active period
resource "aws_db_instance" "replica" {
  count = var.create_read_replica && var.active_period ? 1 : 0
  
  identifier = "${var.environment}-digit-hcm-postgres-replica"
  
  replicate_source_db = aws_db_instance.primary.identifier
  
  instance_class = var.instance_class
  
  vpc_security_group_ids = [aws_security_group.rds.id]
  
  # Reduce replica size during non-active periods (though this is conditional anyway)
  allocated_storage = var.active_period ? var.allocated_storage : var.allocated_storage / 2
  
  skip_final_snapshot = true
  deletion_protection = false
  
  tags = merge(var.tags, {
    Name = "${var.environment}-postgres-replica"
    Active = var.active_period ? "true" : "false"
  })
}

# Store credentials in AWS Secrets Manager
resource "aws_secretsmanager_secret" "database" {
  name = "${var.environment}-database-credentials"
  
  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "database" {
  secret_id = aws_secretsmanager_secret.database.id
  
  secret_string = jsonencode({
    username = var.database_username
    password = local.database_password
    host     = aws_db_instance.primary.address
    port     = aws_db_instance.primary.port
    database = var.database_name
  })
}