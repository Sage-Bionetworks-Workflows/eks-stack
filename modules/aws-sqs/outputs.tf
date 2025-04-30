output "queue_name" {
  description = "The name of the SQS queue"
  value       = var.queue_name
}

output "queue_url" {
  description = "The URL of the SQS queue"
  value       = "https://sqs.${var.aws_region}.amazonaws.com/${var.aws_account_id}/${var.queue_name}"
}

output "api_queue_url" {
  description = "The URL of the API SQS queue"
  value       = aws_sqs_queue.api_queue.url
}

output "api_queue_arn" {
  description = "The ARN of the API SQS queue"
  value       = aws_sqs_queue.api_queue.arn
}

output "api_gateway_url" {
  description = "The URL of the API Gateway endpoint"
  value       = "${aws_apigatewayv2_api.api_gateway.api_endpoint}/${aws_apigatewayv2_stage.api_gateway_stage.name}"
} 
