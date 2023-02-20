# Terraform module for configuration of email reception and processing using SES

Easy configure the reception of emails and processing of attachment 
thanks to SES, S3 storage, SNS notifications, and Lambda functions.
This module set up a fully configurable reception pipeline:

1. Store the email, and attachments in an S3 bucket
2. Trigger a lambda function, allowed to read & write that bucket
3. Send a notification to a SNS topic.

## Usage
**Example**: Collect emails sent to `*@bot.my-domain.be`

Also, look at the example Lambda code for reading messages, and dealing with attachments in S3
* [in Python](./doc/lambda.py)
* in Javascript (TODO)

```terraform
# Domain identity must be validated before any reception to work
# example here with Gandi registar dedicated module
module "gandi_ses_verification" {
  source  = "git::https://github.com/raphaeljoie/terraform-aws-ses-gandi.git"
  
  domain = "my-domain.be"
  mail_from_subdomain = "mail"
}

# This module!
module "ses_reception" {
  source  = "git::https://github.com/raphaeljoie/terraform-aws-ses-reception.git"

  domain = "my-domain.be"
  bucket = "mydomainbotmails"  # Will be created, by default, or could be imported
  lambda_name = "mydomainbotmails"  # Must be existing
  subdmomain = "bot"
}

# pipe emails to reception pipeline. 
# TODO add a `configure_route53` variable to include the resource
resource "aws_route53_record" "redirection" {
  zone_id = data.aws_route53_zone.zone.id
  ttl = 600
  type = module.ses_reception.mx_record.type
  name = module.ses_reception.subdomain
  records = module.ses_reception.mx_record.values
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.1 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 4.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.lambda_s3_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role_policy_attachment.lambda_s3_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lambda_permission.lambda_permission](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_s3_bucket.bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_policy.ses_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_ses_active_receipt_rule_set.enable_this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ses_active_receipt_rule_set) | resource |
| [aws_ses_receipt_rule.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ses_receipt_rule) | resource |
| [aws_ses_receipt_rule_set.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ses_receipt_rule_set) | resource |
| [aws_sns_topic.sns_topic](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic_policy.reception_sns_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_policy) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_role.lambda_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_role) | data source |
| [aws_lambda_function.lambda_function](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/lambda_function) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_sns_topic.sns_topic](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/sns_topic) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS SES region | `string` | `null` | no |
| <a name="input_bucket"></a> [bucket](#input\_bucket) | S3 bucket to keep the message received. Use null value for skipping S3 Bucket storage action | `string` | `null` | no |
| <a name="input_create_bucket"></a> [create\_bucket](#input\_create\_bucket) | If a `bucket` is provided, indicate whether it should be included or created | `bool` | `true` | no |
| <a name="input_create_sns_topic"></a> [create\_sns\_topic](#input\_create\_sns\_topic) | If a `sns_topic` is profided, indicate whether it should be included or created | `bool` | `true` | no |
| <a name="input_domain"></a> [domain](#input\_domain) | Domain name for which the AWS SES mail service must be configured. Domain identity must be verified | `string` | n/a | yes |
| <a name="input_lambda_grant_s3_access"></a> [lambda\_grant\_s3\_access](#input\_lambda\_grant\_s3\_access) | Attach a policy to allow the existing lambda an access to the objects in the S3 `bucket`, if provided. | `bool` | `true` | no |
| <a name="input_lambda_invocation_type"></a> [lambda\_invocation\_type](#input\_lambda\_invocation\_type) | TODO | `string` | `"Event"` | no |
| <a name="input_lambda_name"></a> [lambda\_name](#input\_lambda\_name) | Name of an the lambda lambda function to be triggered. | `string` | `null` | no |
| <a name="input_lambda_policy_name"></a> [lambda\_policy\_name](#input\_lambda\_policy\_name) | TODO | `string` | `null` | no |
| <a name="input_lambda_role_name"></a> [lambda\_role\_name](#input\_lambda\_role\_name) | TODO | `string` | `null` | no |
| <a name="input_lambda_setup_permissions"></a> [lambda\_setup\_permissions](#input\_lambda\_setup\_permissions) | Setup SES permission to execute the existing lambda. | `bool` | `true` | no |
| <a name="input_rule_set_is_active"></a> [rule\_set\_is\_active](#input\_rule\_set\_is\_active) | Should the Redirection Rule Set be enabled | `bool` | `true` | no |
| <a name="input_rule_set_name"></a> [rule\_set\_name](#input\_rule\_set\_name) | Name of the Redirection Rule Set | `string` | `"default"` | no |
| <a name="input_sns_encoding"></a> [sns\_encoding](#input\_sns\_encoding) | Encoding for the SNS topic created, if any | `string` | `"Base64"` | no |
| <a name="input_sns_topic"></a> [sns\_topic](#input\_sns\_topic) | SNS topic to distribute the notification of a new message. Keep null to skip this action | `string` | `null` | no |
| <a name="input_subdomain"></a> [subdomain](#input\_subdomain) | subdomain to which the emails are redirected (@{reception\_subdomain}.{domain}) | `string` | `"bot"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_aws_account_id"></a> [aws\_account\_id](#output\_aws\_account\_id) | n/a |
| <a name="output_aws_region"></a> [aws\_region](#output\_aws\_region) | AWS region used |
| <a name="output_bucket"></a> [bucket](#output\_bucket) | n/a |
| <a name="output_created_bucket_arn"></a> [created\_bucket\_arn](#output\_created\_bucket\_arn) | n/a |
| <a name="output_domain"></a> [domain](#output\_domain) | Static export if `domain` variable |
| <a name="output_lambda_arn"></a> [lambda\_arn](#output\_lambda\_arn) | n/a |
| <a name="output_lambda_function_name"></a> [lambda\_function\_name](#output\_lambda\_function\_name) | n/a |
| <a name="output_lambda_permission_id"></a> [lambda\_permission\_id](#output\_lambda\_permission\_id) | n/a |
| <a name="output_lambda_policy_arn"></a> [lambda\_policy\_arn](#output\_lambda\_policy\_arn) | n/a |
| <a name="output_lambda_policy_id"></a> [lambda\_policy\_id](#output\_lambda\_policy\_id) | n/a |
| <a name="output_lambda_policy_name"></a> [lambda\_policy\_name](#output\_lambda\_policy\_name) | n/a |
| <a name="output_lambda_role_arn"></a> [lambda\_role\_arn](#output\_lambda\_role\_arn) | n/a |
| <a name="output_lambda_s3_policy"></a> [lambda\_s3\_policy](#output\_lambda\_s3\_policy) | n/a |
| <a name="output_mx_record"></a> [mx\_record](#output\_mx\_record) | MX record to be created for piping emails to the reception pipeline configured |
| <a name="output_ses_bucket_policy"></a> [ses\_bucket\_policy](#output\_ses\_bucket\_policy) | n/a |
| <a name="output_subdomain"></a> [subdomain](#output\_subdomain) | Static export if `subdomain` variable |
<!-- END_TF_DOCS -->

## Dev
```sh
terraform-docs markdown table ./ --output-file README.md
```

## TODO
* [ ] bucket path prefix
