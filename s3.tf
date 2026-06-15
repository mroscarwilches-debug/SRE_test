data "aws_caller_identity" "current" {}

# -----------------------------------------------------------------------------
# Bucket de resultados - objetos bajo results/<fecha>/<id>.json
# force_destroy=true permite `terraform destroy` limpio incluso con
# versionado habilitado y objetos presentes (necesario para el ciclo
# apply -> probar -> destroy de este ejercicio).
# -----------------------------------------------------------------------------
resource "aws_s3_bucket" "results" {
  bucket        = "${var.project_name}-results-${data.aws_caller_identity.current.account_id}"
  force_destroy = true

  tags = {
    Name = "${var.project_name}-results"
  }
}

resource "aws_s3_bucket_versioning" "results" {
  bucket = aws_s3_bucket.results.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Block Public Access habilitado en las 4 configuraciones
resource "aws_s3_bucket_public_access_block" "results" {
  bucket = aws_s3_bucket.results.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "results" {
  bucket = aws_s3_bucket.results.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# -----------------------------------------------------------------------------
# Bucket policy - acceso restringido unicamente al rol IAM de Lambda,
# solo para escribir objetos bajo el prefijo results/*
# -----------------------------------------------------------------------------
data "aws_iam_policy_document" "s3_lambda_access" {
  statement {
    sid    = "AllowLambdaPutResults"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.lambda.arn]
    }

    actions = [
      "s3:PutObject",
    ]

    resources = [
      "${aws_s3_bucket.results.arn}/results/*",
    ]
  }
}

resource "aws_s3_bucket_policy" "results" {
  bucket = aws_s3_bucket.results.id
  policy = data.aws_iam_policy_document.s3_lambda_access.json

  depends_on = [aws_s3_bucket_public_access_block.results]
}
