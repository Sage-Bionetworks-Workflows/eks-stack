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

output "api_integration_id" {
  description = "The ID of the API Gateway integration"
  value       = var.enable_api_gateway_integration ? aws_apigatewayv2_integration.sqs_integration[0].id : null
}

output "api_route_key" {
  description = "The route key for the API Gateway route"
  value       = var.enable_api_gateway_integration ? aws_apigatewayv2_route.events_route[0].route_key : null
}

output "access_role_arn" {
  description = "ARN of the role to access the SQS queue"
  value       = aws_iam_role.sqs_access_role.arn
} 
