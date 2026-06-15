data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/lambda_function.py"
  output_path = "${path.module}/lambda/lambda_function.zip"
}

# -----------------------------------------------------------------------------
# Lambda Layer con redis-py, compilada para Linux x86_64/Python 3.12 dentro de
# un contenedor Docker (ver scripts/build_layer.sh). El null_resource de abajo
# corre ese script automaticamente como parte de `terraform apply`, para que
# no haga falta ningun paso manual previo. Solo se re-ejecuta si cambia
# layer/requirements.txt.
#
# Git Bash es el interprete usado para correr el script (.sh). En Windows se
# usa la ruta estandar de instalacion; si no existe (Linux/Mac), se usa "bash"
# del PATH.
# -----------------------------------------------------------------------------
locals {
  bash_path = fileexists("C:/Program Files/Git/bin/bash.exe") ? "C:/Program Files/Git/bin/bash.exe" : "bash"
}

resource "null_resource" "build_redis_layer" {
  triggers = {
    requirements_hash = filesha256("${path.module}/layer/requirements.txt")
  }

  provisioner "local-exec" {
    interpreter = [local.bash_path, "-c"]
    command     = "${path.module}/scripts/build_layer.sh"
  }
}

data "archive_file" "redis_layer_zip" {
  type        = "zip"
  source_dir  = "${path.module}/layer"
  output_path = "${path.module}/layer/redis_layer.zip"
  excludes    = ["redis_layer.zip", "requirements.txt"]

  depends_on = [null_resource.build_redis_layer]
}

resource "aws_lambda_layer_version" "redis" {
  layer_name          = "${var.project_name}-redis-py"
  filename            = data.archive_file.redis_layer_zip.output_path
  source_code_hash    = data.archive_file.redis_layer_zip.output_base64sha256
  compatible_runtimes = [var.lambda_runtime]
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.project_name}-process"
  retention_in_days = var.log_retention_days
}

resource "aws_lambda_function" "process" {
  function_name = "${var.project_name}-process"

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  handler = "lambda_function.lambda_handler"
  runtime = var.lambda_runtime
  role    = aws_iam_role.lambda.arn

  timeout     = var.lambda_timeout
  memory_size = var.lambda_memory_size

  layers = [aws_lambda_layer_version.redis.arn]

  vpc_config {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      REDIS_HOST  = aws_elasticache_cluster.main.cache_nodes[0].address
      REDIS_PORT  = tostring(aws_elasticache_cluster.main.cache_nodes[0].port)
      BUCKET_NAME = aws_s3_bucket.results.bucket
      CACHE_TTL   = tostring(var.cache_ttl_seconds)
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda,
    aws_iam_role_policy_attachment.lambda_vpc_access,
  ]

  tags = {
    Name = "${var.project_name}-process"
  }
}
