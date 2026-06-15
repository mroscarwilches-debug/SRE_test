# -----------------------------------------------------------------------------
# Rol IAM asumido por la funcion Lambda
# -----------------------------------------------------------------------------
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${var.project_name}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

# Managed policy de AWS: da permiso para crear y administrar las conexiones
# de red que la Lambda necesita para vivir dentro de la VPC, además de
# permiso para escribir logs en CloudWatch.
resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# -----------------------------------------------------------------------------
# Policy inline: permiso minimo para escribir resultados en S3 bajo results/*
# -----------------------------------------------------------------------------
data "aws_iam_policy_document" "lambda_s3_put" {
  statement {
    effect = "Allow"

    actions = [
      "s3:PutObject",
    ]

    resources = [
      "${aws_s3_bucket.results.arn}/results/*",
    ]
  }
}

resource "aws_iam_role_policy" "lambda_s3_put" {
  name   = "${var.project_name}-lambda-s3-put"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda_s3_put.json
}
