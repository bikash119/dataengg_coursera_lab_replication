# Create the IAM Policy
resource "aws_iam_policy" "ec2_instance_connect" {
  name        = "EC2InstanceConnectPolicy"
  description = "Policy to allow EC2 Instance Connect usage"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2-instance-connect:SendSSHPublicKey"
        ]
        Resource = "*"  # For production, specify instance ARN
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances"
        ]
        Resource = "*"
      }
    ]
  })
}

