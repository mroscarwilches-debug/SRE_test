# -----------------------------------------------------------------------------
# HTTP API (apigatewayv2) - ver README para justificacion vs REST API
# -----------------------------------------------------------------------------
resource "aws_apigatewayv2_api" "main" {
  name          = "${var.project_name}-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["POST", "OPTIONS"]
    allow_headers = ["content-type"]
    max_age       = 300
  }

  tags = {
    Name = "${var.project_name}-api"
  }
}

resource "aws_cloudwatch_log_group" "api_gw" {
  name              = "/aws/apigateway/${var.project_name}-api"
  retention_in_days = var.log_retention_days
}

# -----------------------------------------------------------------------------
# Stage $default, con throttling y logs de acceso.
# Importante: throttling_rate_limit/burst_limit siempre deben tener un valor
# explicito. Si se omiten, Terraform los deja en 0 por defecto, y eso
# bloquearia todas las peticiones a la API.
# -----------------------------------------------------------------------------
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = "$default"
  auto_deploy = true

  default_route_settings {
    throttling_rate_limit  = var.api_throttling_rate_limit
    throttling_burst_limit = var.api_throttling_burst_limit
  }

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn
    format = jsonencode({
      requestId               = "$context.requestId"
      ip                      = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      httpMethod              = "$context.httpMethod"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      protocol                = "$context.protocol"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
    })
  }

  depends_on = [aws_cloudwatch_log_group.api_gw]

  tags = {
    Name = "${var.project_name}-api-stage"
  }
}

# -----------------------------------------------------------------------------
# Integracion proxy con Lambda
# -----------------------------------------------------------------------------
resource "aws_apigatewayv2_integration" "lambda" {
  api_id = aws_apigatewayv2_api.main.id

  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  integration_uri        = aws_lambda_function.process.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "post_process" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "POST /process"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.process.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}
