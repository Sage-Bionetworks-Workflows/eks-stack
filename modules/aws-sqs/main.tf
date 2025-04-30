resource "helm_release" "ack_sqs_controller" {
  name       = "ack-sqs-controller"
  repository = "oci://public.ecr.aws/aws-controllers-k8s"
  chart      = "sqs-chart"
  version    = "1.0.6"
  namespace  = var.namespace

  set {
    name  = "aws.region"
    value = var.aws_region
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = var.ack_controller_role_arn
  }
}

resource "kubernetes_manifest" "sqs_queue" {
  depends_on = [helm_release.ack_sqs_controller]

  manifest = {
    apiVersion = "sqs.services.k8s.aws/v1alpha1"
    kind       = "Queue"
    metadata = {
      name      = var.queue_name
      namespace = var.namespace
    }
    spec = {
      name = var.queue_name
      queueAttributes = {
        VisibilityTimeout = var.visibility_timeout
        MessageRetentionPeriod = var.message_retention_period
        DelaySeconds = var.delay_seconds
        MaximumMessageSize = var.maximum_message_size
      }
      tags = var.tags
    }
  }
}

resource "aws_sqs_queue" "webhook_test_queue" {
  name                      = "${var.environment}-${var.name}-webhook-test"
  visibility_timeout        = 30
  message_retention_seconds = 345600  # 4 days
  tags = {
    Environment = var.environment
    Name        = var.name
  }
}

resource "aws_sqs_queue_policy" "webhook_test_queue_policy" {
  queue_url = aws_sqs_queue.webhook_test_queue.id
  policy    = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = ["sqs:SendMessage"]
        Resource  = aws_sqs_queue.webhook_test_queue.arn
      }
    ]
  })
}

resource "aws_apigatewayv2_api" "webhook_test_api" {
  name          = "${var.environment}-${var.name}-webhook-test-api"
  protocol_type = "HTTP"
  description   = "API for testing webhooks, forwards events to a testing SQS queue"
}

resource "aws_apigatewayv2_stage" "webhook_test_api_stage" {
  api_id = aws_apigatewayv2_api.webhook_test_api.id
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
        Resource = aws_sqs_queue.webhook_test_queue.arn
      }
    ]
  })
}

resource "aws_apigatewayv2_integration" "webhook_test_sqs_integration" {
  api_id           = aws_apigatewayv2_api.webhook_test_api.id
  integration_type = "AWS_PROXY"
  integration_subtype = "SQS-SendMessage"
  payload_format_version = "1.0"
  credentials_arn = aws_iam_role.api_gateway_sqs_role.arn

  request_parameters = {
    "QueueUrl" = aws_sqs_queue.webhook_test_queue.url
    "MessageBody" = "$request.body"
    "MessageAttributes" = jsonencode({
      "WebhookMessageType" = {
        "DataType" = "String"
        "StringValue" = "$request.header.X-Syn-Webhook-Message-Type"
      }
      "WebhookId" = {
        "DataType" = "String"
        "StringValue" = "$request.header.X-Syn-Webhook-Id"
      }
      "AuthorizationHeader" = {
        "DataType" = "String"
        "StringValue" = "$request.header.Authorization"
      }
    })
  }
}

resource "aws_apigatewayv2_route" "webhook_test_route" {
  api_id    = aws_apigatewayv2_api.webhook_test_api.id
  route_key = "POST /events"
  target    = "integrations/${aws_apigatewayv2_integration.webhook_test_sqs_integration.id}"
} 
