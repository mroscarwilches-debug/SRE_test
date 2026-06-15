output "api_endpoint" {
  description = "URL base de la API HTTP"
  value       = aws_apigatewayv2_api.main.api_endpoint
}

output "process_endpoint_url" {
  description = "URL completa del endpoint POST /process"
  value       = "${aws_apigatewayv2_api.main.api_endpoint}/process"
}

output "s3_bucket_name" {
  description = "Nombre del bucket S3 de resultados"
  value       = aws_s3_bucket.results.bucket
}

output "redis_endpoint" {
  description = "Endpoint (host) del cluster ElastiCache Redis"
  value       = aws_elasticache_cluster.main.cache_nodes[0].address
}

output "redis_port" {
  description = "Puerto del cluster ElastiCache Redis"
  value       = aws_elasticache_cluster.main.cache_nodes[0].port
}

output "lambda_function_name" {
  description = "Nombre de la funcion Lambda de procesamiento"
  value       = aws_lambda_function.process.function_name
}

output "lambda_role_arn" {
  description = "ARN del rol IAM asumido por la funcion Lambda"
  value       = aws_iam_role.lambda.arn
}

output "vpc_id" {
  description = "ID de la VPC creada"
  value       = aws_vpc.main.id
}

output "nat_gateway_id" {
  description = "ID del NAT Gateway (recordatorio: es el principal costo recurrente, eliminar con terraform destroy)"
  value       = aws_nat_gateway.main.id
}
