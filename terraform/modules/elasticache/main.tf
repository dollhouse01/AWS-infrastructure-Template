# Security group for ElastiCache
resource "aws_security_group" "redis" {
  name        = "${var.environment}-redis-sg"
  description = "Security group for Redis ElastiCache"
  vpc_id      = var.vpc_id
  
  ingress {
    description     = "Redis from VPC"
    from_port       = var.port
    to_port         = var.port
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
    Name = "${var.environment}-redis-sg"
  })
}

# Subnet group for ElastiCache
resource "aws_elasticache_subnet_group" "redis" {
  name       = "${var.environment}-redis-subnet-group"
  subnet_ids = var.private_subnet_ids
  
  tags = var.tags
}

# Parameter group for Redis
resource "aws_elasticache_parameter_group" "redis" {
  name   = "${var.environment}-redis-params"
  family = var.parameter_group_family
  
  parameter {
    name  = "maxmemory-policy"
    value = "volatile-lru"
  }
  
  parameter {
    name  = "notify-keyspace-events"
    value = "Ex"
  }
  
  tags = var.tags
}

# Redis replication group
resource "aws_elasticache_replication_group" "redis" {
  replication_group_id = "${var.environment}-digit-redis"
  description         = "Redis cluster for DIGIT HCM ${var.environment}"
  
  node_type = var.node_type
  port      = var.port
  
  parameter_group_name = aws_elasticache_parameter_group.redis.name
  subnet_group_name    = aws_elasticache_subnet_group.redis.name
  security_group_ids   = [aws_security_group.redis.id]
  
  engine         = "redis"
  engine_version = var.engine_version
  
  num_cache_clusters = var.num_cache_nodes
  multi_az_enabled   = var.multi_az && var.num_cache_nodes > 1 ? true : false
  automatic_failover_enabled = var.num_cache_nodes > 1 ? true : false
  
  maintenance_window = var.maintenance_window
  
  snapshot_retention_limit = var.backup_retention_days
  snapshot_window          = var.backup_window
  
  auto_minor_version_upgrade = true
  
  tags = merge(var.tags, {
    Name = "${var.environment}-redis"
  })
}

# Store endpoint in SSM Parameter Store
resource "aws_ssm_parameter" "redis_endpoint" {
  name  = "/${var.environment}/redis/endpoint"
  type  = "String"
  value = aws_elasticache_replication_group.redis.primary_endpoint_address
  
  tags = var.tags
}

resource "aws_ssm_parameter" "redis_port" {
  name  = "/${var.environment}/redis/port"
  type  = "String"
  value = var.port
  
  tags = var.tags
}