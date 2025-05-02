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

# API Gateway to SQS Integration
resource "aws_iam_role" "api_gateway_sqs_role" {
  count = var.enable_api_gateway_integration ? 1 : 0
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
  count = var.enable_api_gateway_integration ? 1 : 0
  name = "${var.environment}-${var.name}-api-gateway-sqs-policy"
  role = aws_iam_role.api_gateway_sqs_role[0].id

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
  count = var.enable_api_gateway_integration ? 1 : 0
  api_id           = var.api_gateway_id
  integration_type = "AWS_PROXY"
  integration_subtype = "SQS-SendMessage"
  payload_format_version = "1.0"
  credentials_arn = aws_iam_role.api_gateway_sqs_role[0].arn

  request_parameters = {
    "QueueUrl" = aws_sqs_queue.queue.url
    "MessageBody" = "$request.body"
    "MessageAttributes" = jsonencode({
      "ApiSource": {
        "DataType": "String",
        "StringValue": "ApiGateway"
      }
    })
  }
}

resource "aws_apigatewayv2_route" "events_route" {
  count = var.enable_api_gateway_integration ? 1 : 0
  api_id    = var.api_gateway_id
  route_key = "POST ${var.route_path}"
  target    = "integrations/${aws_apigatewayv2_integration.sqs_integration[0].id}"
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
