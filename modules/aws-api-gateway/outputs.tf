output "api_id" {
  description = "The ID of the API Gateway"
  value       = aws_apigatewayv2_api.api_gateway.id
}

output "api_endpoint" {
  description = "The HTTP endpoint of the API Gateway"
  value       = aws_apigatewayv2_api.api_gateway.api_endpoint
}

output "api_arn" {
  description = "The ARN of the API Gateway"
  value       = aws_apigatewayv2_api.api_gateway.arn
}

output "stage_id" {
  description = "The ID of the API Gateway default stage"
  value       = aws_apigatewayv2_stage.api_gateway_stage.id
} 
