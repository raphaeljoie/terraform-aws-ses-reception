
locals {
  lambda_function_name = data.aws_lambda_function.lambda_function[0].function_name
}

resource "aws_lambda_permission" "lambda_permission" {
  count = var.lambda_name != null && var.lambda_setup_permissions ? 1 : 0

  statement_id = "AllowSesInvoke"

  action = "lambda:InvokeFunction"
  function_name = local.lambda_function_name
  principal = "ses.amazonaws.com"
  source_account = data.aws_caller_identity.current.account_id
  #source_arn = aws_ses_receipt_rule.this.arn
}

locals {
  lambda_s3_policy = var.bucket != null ? {
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:DeleteObjectTagging",
          "s3:PutObjectTagging",
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ],
        Resource = [
          "arn:aws:s3:::${var.bucket}",
          "arn:aws:s3:::${var.bucket}/*"
        ]
      }],
  } : null
}

resource "aws_iam_policy" "lambda_s3_policy" {
  count = var.lambda_name != null && var.bucket != null && var.lambda_grant_s3_access ? 1 : 0

  name = coalesce(var.lambda_policy_name, "AwsLambdaS3Access-${var.bucket}")

  policy = jsonencode(local.lambda_s3_policy)

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "lambda_s3_policy_attachment" {
  count = var.lambda_name != null && var.bucket != null && var.lambda_grant_s3_access ? 1 : 0

  policy_arn = aws_iam_policy.lambda_s3_policy[0].arn
  role = data.aws_iam_role.lambda_role[0].name
}

## Bucket
resource "aws_s3_bucket" "bucket" {
  count = var.bucket != null && var.create_bucket ? 1 : 0
  bucket = var.bucket
}

locals {
  ses_bucket_policy = var.bucket != null ? {
    Statement = [
      {
        Action = "s3:PutObject"
        Condition = {
          StringEquals = {
            "AWS:SourceAccount" = data.aws_caller_identity.current.account_id
          }
          StringLike = {
            "AWS:SourceArn" = "arn:aws:ses:*"
          }
        }
        Effect = "Allow"
        Principal = {
          Service = "ses.amazonaws.com"
        }
        Resource = "arn:aws:s3:::${aws_s3_bucket.bucket[0].bucket}/*"
        Sid = "AllowSESPuts"
      },
    ]
    Version = "2012-10-17"
  } : null
}

resource "aws_s3_bucket_policy" "ses_bucket_policy" {
  count = var.bucket != null && var.create_bucket ? 1 : 0
  bucket = aws_s3_bucket.bucket[0].bucket
  policy = jsonencode(local.ses_bucket_policy)
}

## SNS
resource "aws_sns_topic" "sns_topic" {
  count = var.sns_topic != null && var.create_sns_topic ? 1 : 0
  name = var.sns_topic
}

resource "aws_sns_topic_policy" "reception_sns_policy" {
  count = var.sns_topic != null && var.create_sns_topic ? 1 : 0

  arn = aws_sns_topic.sns_topic[0].arn
  policy = jsonencode({
    Statement = [
      {
        Action = "SNS:Publish"
        Condition = {
          StringEquals = {
            "AWS:SourceAccount" = data.aws_caller_identity.current.id
          }
          StringLike = {
            "AWS:SourceArn" = "arn:aws:ses:*"
          }
        }
        Effect = "Allow"
        Principal = {
          Service = "ses.amazonaws.com"
        }
        Resource = aws_sns_topic.sns_topic[0].arn
        Sid = "AllowSesPublish"
      },
    ]
    Version = "2008-10-17"
  })
}

########

resource "aws_ses_receipt_rule_set" "this" {
  rule_set_name = var.rule_set_name
}

resource "aws_ses_active_receipt_rule_set" "enable_this" {
  count = var.rule_set_is_active ? 1 : 0
  rule_set_name = aws_ses_receipt_rule_set.this.rule_set_name
}

resource "aws_ses_receipt_rule" "this" {
  name          = "${var.subdomain}.${var.domain}"
  rule_set_name = aws_ses_receipt_rule_set.this.rule_set_name
  recipients    = ["${var.subdomain}.${var.domain}"]
  enabled       = true
  scan_enabled  = true

  add_header_action {
    header_name  = "SesReceiptRule"
    header_value = "${var.subdomain}.${var.domain}"
    position     = 1
  }

  dynamic "s3_action" {
    for_each = toset(var.bucket == null ? [] : [var.bucket])
    content {
      bucket_name = s3_action.key
      position    = 2
    }
  }

  dynamic "lambda_action" {
    for_each = toset(var.lambda_name == null ? [] : [var.lambda_name])
    content {
      function_arn    = data.aws_lambda_function.lambda_function[0].arn
      invocation_type = var.lambda_invocation_type
      position        = 3
    }
  }

  dynamic "sns_action" {
    for_each = toset(var.sns_topic == null ? [] : [var.sns_topic])
    content {
      encoding  = var.sns_encoding
      position  = 4
      topic_arn = var.create_sns_topic ? aws_sns_topic.sns_topic[0].arn : data.aws_sns_topic.sns_topic[0].arn
    }
  }
}
