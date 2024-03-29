resource "aws_s3_bucket" "static_website_bucket" {
  bucket =  "www.nhleltdocs.com"
  force_destroy = true
  acl    = "public-read"

  website {
    index_document = "index.html"
  }

}

resource "aws_ecr_repository" "dbt_model_image_repo" {
  name                 = "dbt_model_image_repo"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_s3_bucket_policy" "static_website_bucket_policy" {
  bucket = aws_s3_bucket.static_website_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "PublicReadGetObject"
        Effect = "Allow"
        Principal = "*"
        Action = [
          "s3:GetObject"
        ]
        Resource = [
          "${aws_s3_bucket.static_website_bucket.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_ecs_cluster" "dbt_ecs_cluster" {
  name = "dbt_ecs_cluster"

}

resource "aws_ecs_cluster_capacity_providers" "serverless_nhl_cluster" {
  cluster_name       = aws_ecs_cluster.dbt_ecs_cluster.name
  capacity_providers = ["FARGATE"]
}


resource "aws_cloudwatch_log_group" "dbt_tasks" {
  name = "/ecs/dbt_tasks"
}

resource "aws_ecs_task_definition" "nhl_dbt_ecs_task" {
  family                   = "nhl_dbt_ecs_task"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 1024
  memory                   = 2048
  network_mode             = "awsvpc"
  execution_role_arn       = "arn:aws:iam::647410971427:role/ecsTaskExecutionRole"
  container_definitions = templatefile("templates/container_definition.tftpl", {
    name             = "dbt_task",
    image            = "${aws_ecr_repository.dbt_model_image_repo.repository_url}:latest",
    cloudwatch_group = "/ecs/dbt_tasks",
    aws_region       = var.aws_region,
    secret_arn = "arn:aws:secretsmanager:us-east-1:647410971427:secret:nhl_elt_snowflake-KowRY3"
  })

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }

  depends_on = [
    docker_registry_image.dbt_model_ecr_image
  ]
}



resource "aws_cloudwatch_event_rule" "dbt_run" {
  name                = "scheduled-ecs-event-rule"
  schedule_expression = "cron(0 11 * * ? *)"

}

resource "aws_cloudwatch_event_target" "scheduled_task" {
  rule      = aws_cloudwatch_event_rule.dbt_run.name
  arn       = aws_ecs_cluster.dbt_ecs_cluster.arn
  role_arn  = aws_iam_role.ecs_events_role.arn

  ecs_target {
    task_count          = 1
    task_definition_arn = aws_ecs_task_definition.nhl_dbt_ecs_task.arn
    launch_type         = "FARGATE"
    network_configuration {
      subnets          = [aws_subnet.dbt_public_subnet.id]
      assign_public_ip = true
      security_groups  = [aws_security_group.dbt_vpc_security_group.id]
    }
  }

  depends_on = [
    aws_cloudwatch_event_rule.dbt_run
  ]
}