resource "aws_iam_policy" "ecs_service_role_policy" {

  name   = "dbt_ecs_service_role_policy"
  policy = <<EOF
{
"Version": "2012-10-17",
"Statement": [
    {
        "Effect": "Allow",
        "Action": [
            "ecr:GetAuthorizationToken",
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage",
            "ecr:Pull",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
        ],
        "Resource": "*"
        },

    {
        "Effect": "Allow",
        "Action": [
            "secretsmanager:GetSecretValue"
        ],
        "Resource": [
            "arn:aws:secretsmanager:us-east-1:647410971427:secret:nhl_elt_snowflake-KowRY3"
        ]
    },
    {
        "Effect": "Allow",
        "Action": [
            "s3:GetObject", 
            "s3:PutObject"
        ],
        "Resource": [
            "arn:aws:secretsmanager:us-east-1:647410971427:secret:nhl_elt_snowflake-KowRY3"
        ]
    }

  ]
}
  EOF
}


data "aws_iam_policy_document" "dbt_ecs_trust_relationship" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    effect = "Allow"
  }

}



data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ecs_events_role" {
  name               = "ecs_events_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
   description = "IAM policy to allow CloudWatch Events to invoke an ECS task"
}

data "aws_iam_policy_document" "ecs_events_run_task_with_any_role" {
  statement {
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["ecs:RunTask"]
    resources = ["*"]
  }
}


resource "aws_iam_role_policy" "ecs_events_run_task_with_any_role" {
  name   = "ecs_events_run_task_with_any_role"
  role   = aws_iam_role.ecs_events_role.id
  policy = data.aws_iam_policy_document.ecs_events_run_task_with_any_role.json
}

resource "aws_iam_role" "dbt_ecs_job_role" {
  name               = "dbt_ecs_job_role"
  assume_role_policy = data.aws_iam_policy_document.dbt_ecs_trust_relationship.json
}

resource "aws_iam_role_policy_attachment" "attach_dbt_ecs_service_role_policy" {
  role       = aws_iam_role.dbt_ecs_job_role.name
  policy_arn = aws_iam_policy.ecs_service_role_policy.arn
}