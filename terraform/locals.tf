locals {
  aws_ecr_url       = "${data.aws_caller_identity.aws_account.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
}