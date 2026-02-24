# Get latest Amazon Linux 2 AMI if not provided
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  ami_id = var.ami_id != null ? var.ami_id : data.aws_ami.amazon_linux_2.id
}

# IAM role for EC2 instances
resource "aws_iam_role" "ec2" {
  name = "${var.environment}-ec2-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
  
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ec2_s3" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.environment}-ec2-profile"
  role = aws_iam_role.ec2.name
  
  tags = var.tags
}

# Security group for EC2 instances
resource "aws_security_group" "ec2" {
  name        = "${var.environment}-ec2-sg"
  description = "Security group for EC2 instances"
  vpc_id      = var.vpc_id
  
  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }
  
  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }
  
  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }
  
  ingress {
    description = "Elasticsearch from VPC"
    from_port   = 9200
    to_port     = 9300
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(var.tags, {
    Name = "${var.environment}-ec2-sg"
  })
}

# EC2 Instances
resource "aws_instance" "main" {
  count = var.instance_count
  
  ami           = local.ami_id
  instance_type = var.instance_type
  subnet_id     = var.public_subnet_ids[count.index % length(var.public_subnet_ids)]
  
  vpc_security_group_ids = [aws_security_group.ec2.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2.name
  
  key_name = var.key_name
  
  user_data = var.user_data != "" ? var.user_data : templatefile("${path.module}/user_data.sh", {
    environment = var.environment
  })
  
  root_block_device {
    volume_type = "gp3"
    volume_size = 50
    encrypted   = true
    
    tags = merge(var.tags, {
      Name = "${var.environment}-ec2-${count.index + 1}-root"
    })
  }
  
  tags = merge(var.tags, {
    Name = "${var.environment}-ec2-${count.index + 1}"
  })
}

# Additional EBS volumes
resource "aws_ebs_volume" "additional" {
  for_each = {
    for idx, vol in flatten([
      for vol_name, vol_config in var.ebs_volumes : [
        for i in range(vol_config.count) : {
          name       = vol_name
          index      = i + 1
          size       = vol_config.size
          type       = vol_config.type
          instance_id = aws_instance.main[i % var.instance_count].id
          az         = aws_instance.main[i % var.instance_count].availability_zone
        }
      ]
    ]) : "${vol.name}-${vol.index}" => vol
  }
  
  availability_zone = each.value.az
  size              = each.value.size
  type              = each.value.type
  encrypted         = true
  
  tags = merge(var.tags, {
    Name = "${var.environment}-ebs-${each.value.name}-${each.value.index}"
  })
}

resource "aws_volume_attachment" "additional" {
  for_each = aws_ebs_volume.additional
  
  device_name = "/dev/sd${substr(each.key, length(each.key)-1, 1)}"
  volume_id   = each.value.id
  instance_id = each.value.tags["Name"] # This needs to be fixed to get correct instance ID
}
