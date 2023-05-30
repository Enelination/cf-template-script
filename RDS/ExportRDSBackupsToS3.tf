# Create the IAM role for the Lambda function
resource "aws_iam_role" "lambda_role" {
  name = "LambdaExecutionRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowLambdaService",
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Attach policies to the IAM role
resource "aws_iam_role_policy_attachment" "rds_access_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "s3_access_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# Create the Lambda function
resource "aws_lambda_function" "export_rds_backups_lambda" {
  function_name    = "ExportRDSBackupsToS3"
  runtime          = "python3.8"
  handler          = "lambda_function.lambda_handler"
  timeout          = 60
  role             = aws_iam_role.lambda_role.arn
  source_code_hash = filebase64sha256("lambda_function.zip")
}

# Create the CloudWatch Events rule
resource "aws_cloudwatch_event_rule" "export_rds_backups_rule" {
  name        = "ExportRDSBackupsToS3Schedule"
  description = "Export RDS backups to S3 on a daily schedule"

  schedule_expression = "rate(1 day)"
}

# Create the CloudWatch Events target to invoke the Lambda function
resource "aws_cloudwatch_event_target" "export_rds_backups_target" {
  rule      = aws_cloudwatch_event_rule.export_rds_backups_rule.name
  target_id = "ExportRDSBackupsToS3Target"
  arn       = aws_lambda_function.export_rds_backups_lambda.arn
}
