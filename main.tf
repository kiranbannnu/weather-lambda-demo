provider "aws" {
  region = var.region  

}

# Data Source to Get AWS Account ID
data "aws_caller_identity" "current" {}



########## Resources ##########
# SQS Queue for Incoming Data
resource "aws_sqs_queue" "weather_data_queue" {
  name = "weather-data-queue"

  tags = {
    Environment = "test"
    Project     = "WeatherDataProcessing"
  }
}

# DynamoDB Table for Storing Aggregated Data
resource "aws_dynamodb_table" "daily_weather_data" {
  name           = "daily-weather-data"
  billing_mode   = "PAY_PER_REQUEST" # Use on-demand mode to avoid provisioned throughput
  hash_key       = "property_id"
  range_key      = "date"

  attribute {
    name = "property_id"
    type = "N"  # Numeric type for primary key
  }

  attribute {
    name = "date"
    type = "S"
  }

  tags = {
    Environment = "test"
    Project     = "WeatherDataProcessing"
  }
}

# IAM Role for Lambda Function
resource "aws_iam_role" "weather_lambda_role" {
  name = "weather-lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com",
        },
      },
    ],
  })

  tags = {
    Environment = "test"
    Project     = "WeatherDataProcessing"
  }
}

# IAM Policies
resource "aws_iam_policy" "dynamodb_policy" {
  name        = "DynamoDBAccessPolicy"
  description = "Policy for Lambda to access DynamoDB table"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:BatchWriteItem",
          "dynamodb:Query"
        ],
        Effect   = "Allow",
        Resource = "arn:aws:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/${aws_dynamodb_table.daily_weather_data.name}"
      }
    ]
  })

  tags = {
    Environment = "test"
    Project     = "WeatherDataProcessing"
  }
}

resource "aws_iam_policy" "sqs_policy" {
  name        = "SQSAccessPolicy"
  description = "Policy for Lambda to access SQS queue"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:ChangeMessageVisibility",
          "sqs:GetQueueAttributes"  # Added permission
        ],
        Effect   = "Allow",
        Resource = "arn:aws:sqs:${var.region}:${data.aws_caller_identity.current.account_id}:${aws_sqs_queue.weather_data_queue.name}"
      }
    ]
  })

  tags = {
    Environment = "test"
    Project     = "WeatherDataProcessing"
  }
}

resource "aws_iam_policy" "cloudwatch_logs_policy" {
  name        = "CloudWatchLogsPolicy"
  description = "Policy for Lambda to write logs to CloudWatch"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })

  tags = {
    Environment = "test"
    Project     = "WeatherDataProcessing"
  }
}

# Attach Policies to Lambda Role
resource "aws_iam_role_policy_attachment" "lambda_dynamodb_policy_attachment" {
  role       = aws_iam_role.weather_lambda_role.name
  policy_arn = aws_iam_policy.dynamodb_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_sqs_policy_attachment" {
  role       = aws_iam_role.weather_lambda_role.name
  policy_arn = aws_iam_policy.sqs_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_cloudwatch_policy_attachment" {
  role       = aws_iam_role.weather_lambda_role.name
  policy_arn = aws_iam_policy.cloudwatch_logs_policy.arn
}

# Lambda Function for Data Processing
resource "aws_lambda_function" "weather_data_processor" {
  filename      = "lambda_function.zip"
  function_name = "weather-data-processor"
  role          = aws_iam_role.weather_lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9" # Specify your Lambda runtime

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.daily_weather_data.name
    }
  }

  tags = {
    Environment = "test"
    Project     = "WeatherDataProcessing"
  }
}

# Event Source Mapping for Lambda and SQS Queue
resource "aws_lambda_event_source_mapping" "lambda_sqs_mapping" {
  event_source_arn = aws_sqs_queue.weather_data_queue.arn
  function_name    = aws_lambda_function.weather_data_processor.arn
  enabled          = true

}
