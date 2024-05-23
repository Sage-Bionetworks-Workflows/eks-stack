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

resource "awscc_bedrock_knowledge_base" "nftc_kb" {
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

resource "awscc_bedrock_agent" "nftc_agent" {
  agent_name    = "nftc-agent"
  service_role  = aws_iam_role.nftc_agent_role.arn
  knowledge_base_id = awscc_bedrock_knowledge_base.nftc_kb.id

  tags = {
    Name = "nftc-agent"
  }
}
