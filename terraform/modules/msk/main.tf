# Security group for MSK
resource "aws_security_group" "msk" {
  name        = "${var.environment}-msk-sg"
  description = "Security group for MSK Kafka"
  vpc_id      = var.vpc_id
  
  ingress {
    description     = "Kafka from VPC"
    from_port       = 9092
    to_port         = 9096
    protocol        = "tcp"
    cidr_blocks     = ["10.0.0.0/8"]
  }
  
  ingress {
    description     = "Zookeeper from VPC"
    from_port       = 2181
    to_port         = 2181
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
    Name = "${var.environment}-msk-sg"
  })
}

# MSK Cluster
resource "aws_msk_cluster" "kafka" {
  cluster_name = "${var.environment}-digit-kafka"
  kafka_version = var.kafka_version
  
  number_of_broker_nodes = var.number_of_broker_nodes
  
  broker_node_group_info {
    instance_type   = var.broker_node_type
    client_subnets  = var.private_subnet_ids
    security_groups = [aws_security_group.msk.id]
    
    storage_info {
      ebs_storage_info {
        volume_size = var.ebs_volume_size
      }
    }
  }
  
  encryption_info {
    encryption_in_transit {
      client_broker = var.client_broker_encryption
      in_cluster    = true
    }
  }
  
  enhanced_monitoring = var.enhanced_monitoring
  
  logging_info {
    broker_logs {
      cloudwatch_logs {
        enabled   = true
        log_group = aws_cloudwatch_log_group.msk.name
      }
      s3 {
        enabled = false
      }
    }
  }
  
  tags = var.tags
}

# CloudWatch Log Group for MSK logs
resource "aws_cloudwatch_log_group" "msk" {
  name = "/aws/msk/${var.environment}-digit-kafka"
  retention_in_days = 30
  
  tags = var.tags
}

# Configuration for MSK - Dynamic based on period
resource "aws_msk_configuration" "config" {
  kafka_versions = [var.kafka_version]
  name           = "${var.environment}-kafka-config-${var.period}"
  
  server_properties = <<PROPERTIES
auto.create.topics.enable = true
default.replication.factor = ${var.period == "active" ? 3 : 2}
min.insync.replicas = ${var.period == "active" ? 2 : 1}
num.partitions = ${var.period == "active" ? 6 : 3}
log.retention.hours = ${var.period == "active" ? 168 : 24}
log.segment.bytes = ${var.period == "active" ? 1073741824 : 268435456}
zookeeper.connection.timeout.ms = 6000
zookeeper.session.timeout.ms = 6000
PROPERTIES
}

# Store broker information in SSM Parameter Store
resource "aws_ssm_parameter" "msk_bootstrap_brokers" {
  name  = "/${var.environment}/msk/bootstrap-brokers"
  type  = "SecureString"
  value = aws_msk_cluster.kafka.bootstrap_brokers
  
  tags = var.tags
}

resource "aws_ssm_parameter" "msk_bootstrap_brokers_tls" {
  name  = "/${var.environment}/msk/bootstrap-brokers-tls"
  type  = "SecureString"
  value = aws_msk_cluster.kafka.bootstrap_brokers_tls
  
  tags = var.tags
}

resource "aws_ssm_parameter" "msk_zookeeper_connect" {
  name  = "/${var.environment}/msk/zookeeper-connect"
  type  = "SecureString"
  value = aws_msk_cluster.kafka.zookeeper_connect_string
  
  tags = var.tags
}
