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
  knowledge_base_name = "nftc-kb"
  s3_bucket           = aws_s3_bucket.nftc_kb_bucket.bucket
  service_role        = aws_iam_role.nftc_kb_role.arn

  tags = {
    Name = "nftc-kb"
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

resource "aws_iam_role_policy" "nftc_agent_policy" {
  name   = "nftc-agent-policy"
  role   = aws_iam_role.nftc_agent_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "bedrock:DescribeKnowledgeBase",
          "bedrock:QueryKnowledgeBase"
        ],
        Resource = [
          awscc_bedrock_knowledge_base.nftc_kb.arn
        ]
      }
    ]
  })
}

resource "aws_bedrockagent_agent_knowledge_base_association" "nftc_kb_association" {
  agent_id             = aws_bedrockagent_agent.nftc_agent.id
  description          = "Example Knowledge base"
  knowledge_base_id    = awscc_bedrock_knowledge_base.nftc_kb.id
  knowledge_base_state = "ENABLED"
}

resource "aws_bedrockagent_agent" "nftc_agent" {
    agent_name    = "nftc-agent"
    service_role  = aws_iam_role.nftc_agent_role.arn
    knowledge_base_id = awscc_bedrock_knowledge_base.nftc_kb.id
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
