resource "aws_iam_role" "api_gateway_role" {
  name = "${local.project_name}-api-gateway-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    project = "license_plate_recognition"
  }
}

resource "aws_iam_policy" "upload_to_s3" {
  name = "${local.project_name}-upload-to-s3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["s3:PutObject*"]
        Effect   = "Allow"
        Resource = [aws_s3_bucket.image_bucket.arn, "${aws_s3_bucket.image_bucket.arn}/*"]
      },
    ]
  })
}

resource "aws_iam_policy_attachment" "attach" {
  name       = "attach-s3-permissions"
  roles      = [aws_iam_role.api_gateway_role.name]
  policy_arn = aws_iam_policy.upload_to_s3.arn
}


resource "aws_iam_role" "cloudwatch" {
  name = "${local.project_name}-api_gateway_cloudwatch_global"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "cloudwatch" {
  name = "default"
  role = aws_iam_role.cloudwatch.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:PutLogEvents",
                "logs:GetLogEvents",
                "logs:FilterLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}
