resource "aws_sqs_queue" "queue" {
  name                       = "${var.environment}-${var.name}"
  visibility_timeout_seconds = var.visibility_timeout
  message_retention_seconds  = var.message_retention_period
  delay_seconds              = var.delay_seconds
  max_message_size           = var.maximum_message_size
  tags = merge(
    var.tags,
    {
      Environment = var.environment
      Name        = var.name
    }
  )
}

resource "aws_sqs_queue_policy" "queue_policy" {
  queue_url = aws_sqs_queue.queue.id
  policy    = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = ["sqs:SendMessage"]
        Resource  = aws_sqs_queue.queue.arn
      }
    ]
  })
}

resource "aws_apigatewayv2_api" "api_gateway" {
  name          = "${var.environment}-${var.name}-api"
  protocol_type = "HTTP"
  description   = "API Gateway for SQS integration"
}

resource "aws_apigatewayv2_stage" "api_gateway_stage" {
  api_id = aws_apigatewayv2_api.api_gateway.id
  name   = "$default"
  auto_deploy = true
}

resource "aws_iam_role" "api_gateway_sqs_role" {
  name = "${var.environment}-${var.name}-api-gateway-sqs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "api_gateway_sqs_policy" {
  name = "${var.environment}-${var.name}-api-gateway-sqs-policy"
  role = aws_iam_role.api_gateway_sqs_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["sqs:SendMessage"]
        Resource = aws_sqs_queue.queue.arn
      }
    ]
  })
}

resource "aws_apigatewayv2_integration" "sqs_integration" {
  api_id           = aws_apigatewayv2_api.api_gateway.id
  integration_type = "AWS_PROXY"
  integration_subtype = "SQS-SendMessage"
  payload_format_version = "1.0"
  credentials_arn = aws_iam_role.api_gateway_sqs_role.arn

  request_parameters = {
    "QueueUrl" = aws_sqs_queue.queue.url
    "MessageBody" = "$request.body"
    "MessageAttributes" = jsonencode({
      "MessageType" = {
        "DataType" = "String"
        "StringValue" = "$request.header.X-Message-Type"
      }
      "MessageId" = {
        "DataType" = "String"
        "StringValue" = "$request.header.X-Message-Id"
      }
      "AuthorizationHeader" = {
        "DataType" = "String"
        "StringValue" = "$request.header.Authorization"
      }
    })
  }
}

resource "aws_apigatewayv2_route" "events_route" {
  api_id    = aws_apigatewayv2_api.api_gateway.id
  route_key = "POST /events"
  target    = "integrations/${aws_apigatewayv2_integration.sqs_integration.id}"
}

resource "aws_iam_policy" "sqs_access_policy" {
  name        = "access-policy-${var.aws_account_id}-${var.environment}-${var.name}"
  description = "Policy to access the SQS queue"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:SendMessage"
        ]
        Resource = aws_sqs_queue.queue.arn
      }
    ]
  })
}

resource "aws_iam_role" "sqs_access_role" {
  name        = "sqs-${var.environment}-${var.name}"
  description = "Assumed role to access the SQS queue with the given permissions."

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = var.cluster_oidc_provider_arn
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "sqs_access_policy_attachment" {
  role       = aws_iam_role.sqs_access_role.name
  policy_arn = aws_iam_policy.sqs_access_policy.arn
} 
