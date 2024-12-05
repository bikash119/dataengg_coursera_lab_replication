data "aws_caller_identity" "current" {}

# Create the IAM Policy

data "aws_iam_policy_document" "instance_connect"{

  statement {
    sid = "ec2InstanceConnect"
    effect = "Allow"
    actions = [
      "ec2-instance-connect:SendSSHPublicKey"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    sid = "describeInstances"
    effect = "Allow"
    actions = [
      "ec2:DescribeInstances"
    ]
    resources = [
      "*"
    ]
  }
}

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}
resource "aws_iam_policy" "ec2_instance_connect" {
  name        = "EC2InstanceConnectPolicy"
  description = "Policy to allow EC2 Instance Connect usage"
  policy      = data.aws_iam_policy_document.instance_connect.json
}
data "aws_iam_policy_document" "glue_service_policy" {
  # Statement 1: General permissions
  statement {
    effect = "Allow"
    actions = [
      "glue:*",
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:ListAllMyBuckets",
      "s3:GetBucketAcl",
      "ec2:DescribeVpcEndpoints",
      "ec2:DescribeRouteTables",
      "ec2:CreateNetworkInterface",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeVpcAttribute",
      "iam:ListRolePolicies",
      "iam:GetRole",
      "iam:GetRolePolicy",
      "cloudwatch:PutMetricData"
    ]
    resources = ["*"]
  }

  # Statement 2: S3 bucket creation permissions
  statement {
    effect = "Allow"
    actions = [
      "s3:CreateBucket",
      "s3:PutBucketPublicAccessBlock"
    ]
    resources = ["arn:aws:s3:::aws-glue-*"]
  }

  # Statement 3: S3 object permissions
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [
      "arn:aws:s3:::aws-glue-*/*",
      "arn:aws:s3:::*/*aws-glue-*/*",
      "arn:aws:s3:::datalake-${data.aws_caller_identity.current.account_id}-*/*"
    ]
  }

  # Statement 4: S3 read permissions
  statement {
    effect = "Allow"
    actions = ["s3:GetObject"]
    resources = [
      "arn:aws:s3:::crawler-public*",
      "arn:aws:s3:::aws-glue-*",
      "arn:aws:s3:::scripts-${data.aws_caller_identity.current.account_id}-*/*"
    ]
  }

  # Statement 5: CloudWatch Logs permissions
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:AssociateKmsKey"
    ]
    resources = ["arn:aws:logs:*:*:log-group:/aws-glue/*"]
  }

  # Statement 6: EC2 tagging permissions with condition
  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateTags",
      "ec2:DeleteTags"
    ]
    resources = [
      "arn:aws:ec2:*:*:network-interface/*",
      "arn:aws:ec2:*:*:security-group/*",
      "arn:aws:ec2:*:*:instance/*"
    ]
    condition {
      test     = "ForAllValues:StringEquals"
      variable = "aws:TagKeys"
      values   = ["aws-glue-service-resource"]
    }
  }
}

# Create the IAM policy resource
resource "aws_iam_policy" "glue_service_policy" {
  name        = "GlueServicePolicy"
  description = "Policy for AWS Glue service"
  policy      = data.aws_iam_policy_document.glue_service_policy.json
}

data "aws_iam_policy_document" "glue_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "glue_role" {
  name               = "glue_role"
  assume_role_policy = data.aws_iam_policy_document.glue_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "glue_policy_role_attachment" {
  role       = aws_iam_role.glue_role.name
  policy_arn = aws_iam_policy.glue_service_policy.arn
}

resource "aws_iam_role" "bastion_role" {
  name = "bastion-host-role"

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
}
resource "aws_iam_role_policy" "bastion_policy" {
  name = "bastion-host-policy"
  role = aws_iam_role.bastion_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "${aws_s3_bucket.scripts.arn}",
          "${aws_s3_bucket.scripts.arn}/*"
        ]
      }
    ]
  })
}

# Instance profile
resource "aws_iam_instance_profile" "bastion_profile" {
  name = "bastion-host-profile"
  role = aws_iam_role.bastion_role.name
}