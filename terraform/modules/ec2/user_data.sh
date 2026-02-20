#!/bin/bash
set -ex

# Update system
yum update -y

# Install common utilities
yum install -y git curl wget vim telnet net-tools bind-utils

# Install Docker
amazon-linux-extras install docker -y
systemctl enable docker
systemctl start docker
usermod -a -G docker ec2-user

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install Java (for Elasticsearch)
amazon-linux-extras install java-openjdk11 -y

# Set system parameters for Elasticsearch
cat >> /etc/sysctl.conf <<EOF
vm.max_map_count=262144
EOF
sysctl -p

# Create directories for volumes
mkdir -p /data/{es-master,es-data,monitoring}
chmod 755 /data

# Format and mount additional EBS volumes if they exist
for vol in /dev/sd[b-z]; do
    if [ -e $vol ]; then
        mkfs.xfs $vol
        mount_point="/data/vol-$(basename $vol)"
        mkdir -p $mount_point
        mount $vol $mount_point
        echo "$vol $mount_point xfs defaults 0 0" >> /etc/fstab
    fi
done

# Set environment tag - FIXED: Escaped with $${
echo "ENVIRONMENT=$${environment}" >> /etc/environment

# Install CloudWatch agent
yum install -y amazon-cloudwatch-agent

# Configure CloudWatch agent
cat > /opt/aws/amazon-cloudwatch-agent/bin/config.json <<EOF
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "root"
  },
  "metrics": {
    "append_dimensions": {
      "AutoScalingGroupName": "${aws:AutoScalingGroupName}",
      "ImageId": "${aws:ImageId}",
      "InstanceId": "${aws:InstanceId}",
      "InstanceType": "${aws:InstanceType}"
    },
    "metrics_collected": {
      "disk": {
        "measurement": [
          "used_percent"
        ],
        "metrics_collection_interval": 60,
        "resources": [
          "*"
        ]
      },
      "mem": {
        "measurement": [
          "mem_used_percent"
        ],
        "metrics_collection_interval": 60
      },
      "cpu": {
        "measurement": [
          "cpu_usage_idle",
          "cpu_usage_iowait",
          "cpu_usage_user",
          "cpu_usage_system"
        ],
        "metrics_collection_interval": 60,
        "resources": [
          "*"
        ],
        "totalcpu": false
      }
    }
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/messages",
            "log_group_name": "/$${environment}/ec2/messages",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/secure",
            "log_group_name": "/$${environment}/ec2/secure",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/cloud-init.log",
            "log_group_name": "/$${environment}/ec2/cloud-init",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  }
}
EOF

# Start CloudWatch agent
systemctl enable amazon-cloudwatch-agent
systemctl start amazon-cloudwatch-agent

echo "EC2 instance initialization complete"
