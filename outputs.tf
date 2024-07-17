
# Outputs
output "sqs_queue_url" {
  value = aws_sqs_queue.weather_data_queue.id
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.daily_weather_data.name
}

output "lambda_function_name" {
  value = aws_lambda_function.weather_data_processor.function_name
}
