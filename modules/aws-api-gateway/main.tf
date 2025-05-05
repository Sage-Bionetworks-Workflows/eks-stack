resource "aws_apigatewayv2_api" "api_gateway" {
  name          = "${var.environment}-${var.name}-api"
  protocol_type = "HTTP"
  description   = "API Gateway for various integrations"
  tags          = var.tags
}

resource "aws_apigatewayv2_stage" "api_gateway_stage" {
  api_id = aws_apigatewayv2_api.api_gateway.id
  name   = "$default"
  auto_deploy = true
  tags        = var.tags
} 
