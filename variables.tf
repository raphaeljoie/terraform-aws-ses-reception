variable "aws_region" {
  type        = string
  default     = null
  description = "AWS SES region"
}


variable "domain" {
  type        = string
  description = "Domain name for which the AWS SES mail service must be configured. Domain identity must be verified"
}

variable "subdomain" {
  type        = string
  default     = "bot"
  description = "subdomain to which the emails are redirected (@{reception_subdomain}.{domain})"
}

variable "rule_set_name" {
  type        = string
  default     = "default"
  description = "Name of the Redirection Rule Set"
}

variable "rule_set_is_active" {
  type        = bool
  default     = true
  description = "Should the Redirection Rule Set be enabled"
}

variable "create_bucket" {
  type        = bool
  default     = true
  description = "If a `bucket` is provided, indicate whether it should be included or created"
}

variable "create_sns_topic" {
  type        = bool
  default     = true
  description = "If a `sns_topic` is profided, indicate whether it should be included or created"
}

variable "lambda_name" {
  type        = string
  default     = null
  description = "Name of an the lambda lambda function to be triggered."
}

variable "lambda_role_name" {
  type = string
  default = null
  description = "TODO"
}

variable "lambda_setup_permissions" {
  type        = bool
  default     = true
  description = "Setup SES permission to execute the existing lambda."
}

variable "lambda_grant_s3_access" {
  type        = bool
  default     = true
  description = "Attach a policy to allow the existing lambda an access to the objects in the S3 `bucket`, if provided."
}

variable "lambda_policy_name" {
  type = string
  default = null
  description = "TODO"
}

variable "lambda_invocation_type" {
  type        = string
  default     = "Event"
  description = "TODO"
}

variable "bucket" {
  type        = string
  default     = null
  description = "S3 bucket to keep the message received. Use null value for skipping S3 Bucket storage action"
}

variable "sns_topic" {
  type        = string
  default     = null
  description = "SNS topic to distribute the notification of a new message. Keep null to skip this action"
}

variable "sns_encoding" {
  type        = string
  default     = "Base64"
  description = "Encoding for the SNS topic created, if any"
}