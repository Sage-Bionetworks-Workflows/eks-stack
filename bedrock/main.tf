resource "aws_s3_bucket" "nftc_kb_bucket" {
  bucket = "nftc-kb-bucket"

  tags = {
    Name = "nftc-kb-bucket"
  }
}

resource "aws_iam_role" "nftc_kb_role" {
  name = "nftc-kb-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "bedrock.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "nftc-kb-role"
  }
}

resource "aws_iam_role_policy" "nftc_kb_policy" {
  name   = "nftc-kb-policy"
  role   = aws_iam_role.nftc_kb_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject"
        ],
        Resource = [
          aws_s3_bucket.nftc_kb_bucket.arn,
          "${aws_s3_bucket.nftc_kb_bucket.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_bedrock_knowledge_base" "nftc_kb" {
  name = "nftc-kb"
  role_arn        = aws_iam_role.nftc_kb_role.arn
  knowledge_base_configuration {
    vector_knowledge_base_configuration {
      embedding_model_arn = "arn:aws:bedrock:us-west-2::foundation-model/amazon.titan-embed-text-v1"
    }
    type = "VECTOR"
  }
  tags = {
    Name = "nftc-kb"
  }
}

resource "aws_bedrockagent_data_source" "example" {
  knowledge_base_id = aws_bedrock_knowledge_base.nftc_kb.id
  name              = "nftc-kb-datasource"
  data_source_configuration {
    type = "S3"
    s3_configuration {
      bucket_arn = aws_s3_bucket.nftc_kb_bucket.arn
    }
  }
}

resource "aws_iam_role" "nftc_agent_role" {
  name = "nftc-agent-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "bedrock.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "nftc-agent-role"
  }
}



data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_region" "current" {}

data "aws_iam_policy_document" "example_agent_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["bedrock.amazonaws.com"]
      type        = "Service"
    }
    condition {
      test     = "StringEquals"
      values   = [data.aws_caller_identity.current.account_id]
      variable = "aws:SourceAccount"
    }
    condition {
      test     = "ArnLike"
      values   = ["arn:${data.aws_partition.current.partition}:bedrock:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:agent/*"]
      variable = "AWS:SourceArn"
    }
  }
}

data "aws_iam_policy_document" "example_agent_permissions" {
  statement {
    actions = ["bedrock:InvokeModel"]
    resources = [
      "arn:${data.aws_partition.current.partition}:bedrock:${data.aws_region.current.name}::foundation-model/anthropic.claude-v2",
    ]
  }
}

resource "aws_iam_role" "example" {
  assume_role_policy = data.aws_iam_policy_document.example_agent_trust.json
  name_prefix        = "AmazonBedrockExecutionRoleForAgents_"
}

resource "aws_iam_role_policy" "example" {
  policy = data.aws_iam_policy_document.example_agent_permissions.json
  role   = aws_iam_role.example.id
}


resource "aws_bedrockagent_agent_knowledge_base_association" "nftc_kb_association" {
  agent_id             = aws_bedrockagent_agent.nftc_agent.id
  description          = "Example Knowledge base"
  knowledge_base_id    = awscc_bedrock_knowledge_base.nftc_kb.id
  knowledge_base_state = "ENABLED"
}

resource "aws_bedrockagent_agent" "nftc_agent" {
    agent_name    = "nftc-agent"
    agent_resource_role_arn     = aws_iam_role.example.arn
    foundation_model            = "anthropic.claude-v3-sonnet"
    instruction = """
    Your task is to extract data about research tools, such as animal models and cell lines biobanks from scientific publications. When provided with a name or synonym for a research tool, you will generate a comprehensive list of temporal "observations" about the research tool that describe the natural history of the model as they relate to development or age. For example, an observation could be "The pigs developed tumor type X at Y months of age." Do not include observations about humans with NF1. Your response must be formatted to be compliant with the following JSON:
    [
        {
            resourceType: [Animal Model, Cell Line],
            observationText: This is an example sentence.,
            observationType: [Body Length, Body weight, Coat Color, Disease Susceptibility, Feed Intake, Feeding Behavior, Growth rate, Motor Activity, Organ Development, Reflex Development, Reproductive Behavior, Social Behavior, Swimming Behavior, Tumor Growth, Issue, Depositor Comment, Usage Instructions, General Comment or Review, Other],
            observationPhase: [prenatal, postnatal, null],
            observationTime: a double; the time during the development of the organism which the observation occurred,
            observationTimeUnits: [days, weeks, months, years]
        }
    ]
    """
    tags = {
        Name = "nftc-agent"
    }
}
