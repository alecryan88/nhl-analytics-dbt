#model image is used to run dbt w/ ECS
# This is for ECR Model Image
resource "docker_image" "dbt_model_image" {
  name = "${aws_ecr_repository.dbt_model_image_repo.repository_url}:latest"
  build {
    context    = "./dbt"
    dockerfile = "Dockerfile"
  }
  force_remove = true
  triggers ={
    dockerfile = md5(file("${path.module}/dbt/Dockerfile"))
  }
}

# This is for ECR Model Image
resource "docker_registry_image" "dbt_model_ecr_image" {
  name          = "${aws_ecr_repository.dbt_model_image_repo.repository_url}:latest"
  keep_remotely = true

  depends_on = [
    docker_image.dbt_model_image
  ]
}