locals {
  aws_ecr_url       = "${data.aws_caller_identity.aws_account.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
  manifest          = jsondecode((file("dbt/nhl_dbt/target/manifest.json")))
  model_child_graph = { for k, v in local.manifest.child_map : replace(k, ".", "_") => v if split(".", k)[0] == "model" }
}