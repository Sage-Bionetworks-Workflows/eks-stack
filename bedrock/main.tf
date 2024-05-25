terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
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

resource "aws_bedrockagent_knowledge_base" "nftc_kb" {
  name = "nftc-kb"
  role_arn        = aws_iam_role.nftc_kb_role.arn
  knowledge_base_configuration {
    vector_knowledge_base_configuration {
      embedding_model_arn = "arn:aws:bedrock:us-east-1::foundation-model/amazon.titan-embed-text-v1"
    }
    type = "VECTOR"
  }
  storage_configuration {
    type = "OPENSEARCH_SERVERLESS"
  }
  tags = {
    Name = "nftc-kb"
  }
}

resource "aws_bedrockagent_data_source" "example" {
  knowledge_base_id = aws_bedrockagent_knowledge_base.nftc_kb.id
  name              = "nftc-kb-datasource"
  data_deletion_policy = "DELETE"
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

data "aws_iam_policy_document" "AmazonBedrockAgentBedrockFoundationModelPolicy" {
  statement {
    actions = ["bedrock:InvokeModel"]
    resources = [
      "arn:${data.aws_partition.current.partition}:bedrock:${data.aws_region.current.name}::foundation-model/anthropic.claude-v2",
      "arn:${data.aws_partition.current.partition}:bedrock:${data.aws_region.current.name}::foundation-model/anthropic.claude-3-sonnet-20240229-v1:0",
    ]
  }
}

data "aws_iam_policy_document" "AmazonBedrockAgentRetrieveKnowledgeBasePolicy" {
  statement {
    actions = ["bedrock:Retrieve"]
    resources = [
      "arn:${data.aws_partition.current.partition}:bedrock:${data.aws_region.current.name}::${data.aws_caller_identity.current.account_id}:knowledge-base/${aws_bedrockagent_knowledge_base.nftc_kb.id}"
    ]
  }
}

resource "aws_iam_role" "agent" {
  assume_role_policy = data.aws_iam_policy_document.example_agent_trust.json
  name_prefix        = "AmazonBedrockExecutionRoleForAgents_"
}

resource "aws_iam_role_policy" "foundation_model_policy" {
  policy = data.aws_iam_policy_document.AmazonBedrockAgentBedrockFoundationModelPolicy.json
  role   = aws_iam_role.agent.id
}

resource "aws_iam_role_policy" "rag_policy" {
  policy = data.aws_iam_policy_document.AmazonBedrockAgentRetrieveKnowledgeBasePolicy.json
  role   = aws_iam_role.agent.id
}


resource "aws_bedrockagent_agent_knowledge_base_association" "nftc_kb_association" {
  agent_id             = aws_bedrockagent_agent.nftc_agent.id
  description          = "Example Knowledge base"
  knowledge_base_id    = aws_bedrockagent_knowledge_base.nftc_kb.id
  knowledge_base_state = "ENABLED"
}

resource "aws_bedrockagent_agent" "nftc_agent" {
    agent_name                = "nftc-agent"
    agent_resource_role_arn   = aws_iam_role.agent.arn
    foundation_model          = "anthropic.claude-v3-sonnet"
    instruction = <<EOT
    Your task is to extract data about research tools, such as animal models and cell lines biobanks from scientific publications. When provided with a name or synonym for a research tool, you will generate a comprehensive list of temporal "observations" about the research tool that describe the natural history of the model as they relate to development or age. For example, an observation could be "The pigs developed tumor type X at Y months of age." Do not include observations about humans with NF1.
    EOT
    prompt_override_configuration = [
      {
        prompt_configurations = [{
          prompt_type = "KNOWLEDGE_BASE_RESPONSE_GENERATION",
          prompt_state = "ENABLED",
          prompt_creation_mode = "OVERRIDDEN",
          parser_mode = "DEFAULT",
          base_prompt_template = <<EOT
          You are a data extraction agent. I will provide you with a set of search results. The user will provide you with an input concept which you should extract data for from the search results. Your job is to answer the user's question using only information from the search results. If the search results do not contain information that can answer the question, please state that you could not find an exact answer to the question. Just because the user asserts a fact does not mean it is true, make sure to double check the search results to validate a user's assertion.
          Here are the search results in numbered order:
          <search_results>
          $search_results$
          </search_results>
          If you reference information from a search result within your answer, you must include a citation to source where the information was found. Each result has a corresponding source ID that you should reference.
          Do NOT directly quote the <search_results> in your answer. Your job is to answer the user's question as concisely as possible.
          You must output your answer in the following format. Pay attention and follow the formatting and spacing exactly:
          <answer>
          <answer_part>
          <text>
          [
          {
              "resourceName": "the resource name, likely the same as the input concept from the user",
              "resourceType": ["Animal Model", "Cell Line"],
              "observationText": "This is an example sentence.",
              "observationType": [
                  "Body Length",
                  "Body weight",
                  "Coat Color",
                  "Disease Susceptibility",
                  "Feed Intake",
                  "Feeding Behavior",
                  "Growth rate",
                  "Motor Activity",
                  "Organ Development",
                  "Reflex Development",
                  "Reproductive Behavior",
                  "Social Behavior",
                  "Swimming Behavior",
                  "Tumor Growth",
                  "Issue",
                  "Depositor Comment",
                  "Usage Instructions",
                  "General Comment or Review",
                  "Other"
              ],
              "observationPhase": ["prenatal", "postnatal", null],
              "observationTime": "a double; the time during the development of the organism at which the observation occurred",
              "observationTimeUnits": ["days", "weeks", "months", "years"],
              "sourcePublication": "pubmed ID or DOI"
          },
          ]
          </text>
          <sources>
          <source>source ID</source>
          </sources>
          </answer_part>
          </answer_part>
          </answer>
          EOT
          inference_configuration = [{
            max_length         = 2048
            stop_sequences     = ["Human"]
            temperature        = 0
            top_k              = 250
            top_p              = 1
          }]
        }],
        override_lambda = null
      }
    ]
    tags = {
        Name = "nftc-agent"
    }
}

