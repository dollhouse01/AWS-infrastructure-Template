# Cross-account IAM roles for CI/CD
resource "aws_iam_role" "ci_cd" {
  name = "ci-cd-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.ci_account_id}:root"
        }
        Action = "sts:AssumeRole"
        Condition = {
          Bool = {
            "aws:MultiFactorAuthPresent": "true"
          }
        }
      }
    ]
  })
  
  tags = var.tags
}

resource "aws_iam_role_policy" "ci_cd" {
  name = "ci-cd-policy"
  role = aws_iam_role.ci_cd.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:Describe*",
          "eks:Describe*",
          "eks:List*",
          "iam:Get*",
          "iam:List*",
          "s3:Get*",
          "s3:List*",
          "s3:PutObject",
          "s3:DeleteObject",
          "cloudformation:Describe*",
          "cloudformation:Get*",
          "cloudformation:List*",
          "cloudformation:Create*",
          "cloudformation:Update*",
          "cloudformation:Delete*"
        ]
        Resource = ["*"]
      }
    ]
  })
}

# Organization account access role
resource "aws_iam_role" "organization_access" {
  name = "organization-access-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.organization_id}:root"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
  
  tags = var.tags
}