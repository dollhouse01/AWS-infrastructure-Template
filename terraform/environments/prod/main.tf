locals {
  environment = "prod"
  region      = "af-south-1"
  
  vpc_cidr = "10.2.0.0/16"
  availability_zones = ["af-south-1a", "af-south-1b"]
  
  private_subnet_cidrs = ["10.2.1.0/24", "10.2.2.0/24"]
  public_subnet_cidrs  = ["10.2.101.0/24", "10.2.102.0/24"]
  
  # Determine if we're in active period based on current date
  is_active_period = var.current_period == "active"
  
  tags = {
    Environment = local.environment
    Region      = local.region
    ManagedBy   = "Terraform"
    ActivePeriod = local.is_active_period ? "true" : "false"
  }
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_name
  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
  depends_on = [module.eks]
}

module "iam" {
  source = "../../modules/iam"
  
  environment = local.environment
  region      = local.region
}

module "networking" {
  source = "../../modules/networking"
  
  environment         = local.environment
  region              = local.region
  vpc_cidr            = local.vpc_cidr
  availability_zones  = local.availability_zones
  private_subnet_cidrs = local.private_subnet_cidrs
  public_subnet_cidrs  = local.public_subnet_cidrs
  
  tags = local.tags
}

module "eks" {
  source = "../../modules/eks"
  
  environment        = local.environment
  region             = local.region
  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  public_subnet_ids  = module.networking.public_subnet_ids
  active_start_date  = var.active_start_date
  active_end_date    = var.active_end_date
  
  node_groups = {
    spot_main = {
      desired_size       = local.is_active_period ? 2 : 1
      min_size          = 1
      max_size          = local.is_active_period ? 5 : 2
      instance_types    = ["r6i.4xlarge"]
      spot_instance_types = ["r6i.4xlarge", "m6i.4xlarge", "c6i.4xlarge"]
      capacity_type     = "SPOT"
      use_spot          = var.use_spot_instances
      k8s_labels = {
        Environment = local.environment
        NodeGroup   = "spot-main"
        Period      = local.is_active_period ? "active" : "idle"
      }
    }
    
    on_demand_main = {
      desired_size       = local.is_active_period ? 1 : 1
      min_size          = 1
      max_size          = 2
      instance_types    = ["r6i.4xlarge"]
      spot_instance_types = []
      capacity_type     = "ON_DEMAND"
      use_spot          = false
      k8s_labels = {
        Environment = local.environment
        NodeGroup   = "on-demand-main"
      }
    }
  }
  
  tags = local.tags
}

module "rds" {
  source = "../../modules/rds"
  
  environment        = local.environment
  region             = local.region
  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  
  instance_class      = local.is_active_period ? "db.m6g.2xlarge" : "db.m6g.xlarge"
  allocated_storage   = local.is_active_period ? 100 : 50
  storage_type        = "gp3"
  
  database_name       = "digithcm_prod"
  database_username   = "digithcm_admin"
  
  create_read_replica = local.is_active_period
  active_period       = local.is_active_period
  multi_az            = local.is_active_period ? true : false
  
  backup_retention_period = local.is_active_period ? 30 : 7
  
  tags = local.tags
}

module "elasticache" {
  source = "../../modules/elasticache"
  
  environment        = local.environment
  region             = local.region
  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  
  node_type          = local.is_active_period ? "cache.r5.large" : "cache.t3.medium"
  num_cache_nodes    = local.is_active_period ? 2 : 1
  engine_version     = "7.0"
  multi_az           = local.is_active_period ? true : false
  
  tags = local.tags
}

module "msk" {
  source = "../../modules/msk"
  
  environment        = local.environment
  region             = local.region
  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  
  broker_node_type   = "kafka.m5.large"
  number_of_broker_nodes = local.is_active_period ? 3 : 2
  ebs_volume_size    = local.is_active_period ? 200 : 100
  period             = var.current_period
  
  tags = local.tags
}

module "ec2" {
  source = "../../modules/ec2"
  
  environment        = local.environment
  region             = local.region
  vpc_id             = module.networking.vpc_id
  public_subnet_ids  = module.networking.public_subnet_ids
  
  instance_type      = local.is_active_period ? "r6i.4xlarge" : "t3.xlarge"
  instance_count     = local.is_active_period ? 3 : 1
  
  ebs_volumes = {
    es_master = {
      size = local.is_active_period ? 10 : 5
      count = local.is_active_period ? 3 : 1
      type = "gp3"
    }
    es_data = {
      size = local.is_active_period ? 200 : 100
      count = local.is_active_period ? 3 : 1
      type = "gp3"
    }
    monitoring = {
      size = local.is_active_period ? 30 : 20
      count = local.is_active_period ? 5 : 2
      type = "gp3"
    }
  }
  
  tags = local.tags
}

module "loadbalancer" {
  source = "../../modules/loadbalancer"
  
  environment        = local.environment
  region             = local.region
  vpc_id             = module.networking.vpc_id
  public_subnet_ids  = module.networking.public_subnet_ids
  
  idle_timeout       = local.is_active_period ? 60 : 300
  
  tags = local.tags
}

module "monitoring" {
  source = "../../modules/monitoring"
  
  environment        = local.environment
  region             = local.region
  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  
  ebs_volume_size    = local.is_active_period ? 30 : 20
  volume_count       = local.is_active_period ? 5 : 2
  
  tags = local.tags
}