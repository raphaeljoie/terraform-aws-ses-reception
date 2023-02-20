output "mx_record" {
  value = {
    type = "MX"
    values = ["10 inbound-smtp.${local.aws_region}.amazonaws.com."]
  }
  description = "MX record to be created for piping emails to the reception pipeline configured"
}

output "aws_region" {
  value       = local.aws_region
  description = "AWS region used"
}

output "aws_account_id" {
  value = data.aws_caller_identity.current.id
}

output "lambda_function_name" {
  value = local.lambda_function_name
}

output "lambda_arn" {
  value = var.lambda_name != null ? data.aws_lambda_function.lambda_function[0].arn : null
}

output "lambda_role_arn" {
  value = var.lambda_name != null ? data.aws_iam_role.lambda_role[0].arn : null
}

output "lambda_permission_id" {
  value = var.lambda_name == null || !var.lambda_setup_permissions ? null : aws_lambda_permission.lambda_permission[0].id
}

output "lambda_policy_arn" {
  value = var.lambda_name != null && var.lambda_grant_s3_access ? aws_iam_policy.lambda_s3_policy[0].arn : null
}

output "lambda_policy_id" {
  value = var.lambda_name != null && var.lambda_grant_s3_access ? aws_iam_policy.lambda_s3_policy[0].id : null
}

output "lambda_policy_name" {
  value = var.lambda_name != null && var.lambda_grant_s3_access ? aws_iam_policy.lambda_s3_policy[0].name : null
}

output "lambda_s3_policy" {
  value = local.lambda_s3_policy
}

output "bucket" {
  value = var.bucket
}

output "created_bucket_arn" {
  value = var.bucket != null && var.create_bucket ? aws_s3_bucket.bucket[0].arn : null
}

output "ses_bucket_policy" {
  value = local.ses_bucket_policy
}

# Static exports

output "domain" {
  value       = var.domain
  description = "Static export if `domain` variable"
}

output "subdomain" {
  value       = var.subdomain
  description = "Static export if `subdomain` variable"
}
