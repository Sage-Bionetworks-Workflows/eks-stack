output "queue_name" {
  description = "The name of the SQS queue"
  value       = var.queue_name
}

output "queue_url" {
  description = "The URL of the SQS queue"
  value       = "https://sqs.${var.aws_region}.amazonaws.com/${var.aws_account_id}/${var.queue_name}"
}

output "sqs_queue_url" {
  description = "The URL of the SQS queue"
  value       = aws_sqs_queue.webhook_test_queue.url
}

output "sqs_queue_arn" {
  description = "The ARN of the SQS queue"
  value       = aws_sqs_queue.webhook_test_queue.arn
}

output "api_gateway_url" {
  description = "The URL of the API Gateway endpoint"
  value       = "${aws_apigatewayv2_api.webhook_test_api.api_endpoint}/${aws_apigatewayv2_stage.webhook_test_api_stage.name}"
} 
