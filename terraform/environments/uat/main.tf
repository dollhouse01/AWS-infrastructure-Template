locals {
  environment = "uat"
  region      = "af-south-1"
  
  vpc_cidr = "10.1.0.0/16"
  availability_zones = ["af-south-1a", "af-south-1b"]
  
  private_subnet_cidrs = ["10.1.1.0/24", "10.1.2.0/24"]
  public_subnet_cidrs  = ["10.1.101.0/24", "10.1.102.0/24"]
  
  tags = {
    Environment = local.environment
    Region      = local.region
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
  
  node_groups = {
    main = {
      desired_size = 2
      min_size     = 2
      max_size     = 5
      
      instance_types = ["r6i.4xlarge"]
      
      k8s_labels = {
        Environment = local.environment
        NodeGroup   = "main"
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
  
  instance_class      = "db.m6g.xlarge"
  allocated_storage   = 100
  storage_type        = "gp3"
  
  database_name       = "digithcm_uat"
  database_username   = "digithcm_admin"
  
  create_read_replica = true
  
  tags = local.tags
}

module "elasticache" {
  source = "../../modules/elasticache"
  
  environment        = local.environment
  region             = local.region
  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  
  node_type          = "cache.r5.large"
  num_cache_nodes    = 1
  engine_version     = "7.0"
  
  tags = local.tags
}

module "msk" {
  source = "../../modules/msk"
  
  environment        = local.environment
  region             = local.region
  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  
  broker_node_type   = "kafka.m5.large"
  number_of_broker_nodes = 3
  ebs_volume_size    = 200
  
  tags = local.tags
}

module "ec2" {
  source = "../../modules/ec2"
  
  environment        = local.environment
  region             = local.region
  vpc_id             = module.networking.vpc_id
  public_subnet_ids  = module.networking.public_subnet_ids
  
  instance_type      = "r6i.4xlarge"
  instance_count     = 3
  
  ebs_volumes = {
    es_master = {
      size = 10
      count = 3
      type = "gp3"
    }
    es_data = {
      size = 200
      count = 3
      type = "gp3"
    }
    monitoring = {
      size = 30
      count = 5
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
  
  tags = local.tags
}

module "monitoring" {
  source = "../../modules/monitoring"
  
  environment        = local.environment
  region             = local.region
  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  
  ebs_volume_size    = 30
  volume_count       = 5
  
  tags = local.tags
}