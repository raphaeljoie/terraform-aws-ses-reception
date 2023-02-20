data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  aws_region = var.aws_region == null ? data.aws_region.current.name : var.aws_region
}

data "aws_lambda_function" "lambda_function" {
  count = var.lambda_name != null ? 1 : 0
  function_name = var.lambda_name
}

data "aws_iam_role" "lambda_role" {
  count = var.lambda_name != null ? 1 : 0

  name = element(split("/", element(split(":", data.aws_lambda_function.lambda_function[0].role), 5)),2)
}

data "aws_sns_topic" "sns_topic" {
  count = var.sns_topic != null && !var.create_sns_topic ? 1 : 0

  name = var.sns_topic
}
