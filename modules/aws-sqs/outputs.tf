output "queue_name" {
  description = "The name of the SQS queue"
  value       = aws_sqs_queue.queue.name
}

output "queue_url" {
  description = "The URL of the SQS queue"
  value       = aws_sqs_queue.queue.url
}

output "queue_arn" {
  description = "The ARN of the SQS queue"
  value       = aws_sqs_queue.queue.arn
}

output "api_gateway_url" {
  description = "The URL of the API Gateway endpoint"
  value       = "${aws_apigatewayv2_api.api_gateway.api_endpoint}/${aws_apigatewayv2_stage.api_gateway_stage.name}"
}

output "access_role_arn" {
  description = "ARN of the role to access the SQS queue"
  value       = aws_iam_role.sqs_access_role.arn
} 
