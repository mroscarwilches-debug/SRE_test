# -----------------------------------------------------------------------------
# Security Group de la Lambda
# Sin reglas inline: el egress se define abajo como recursos separados, con
# el minimo necesario (Redis en 6379, HTTPS en 443 para NAT/VPC endpoint S3).
# -----------------------------------------------------------------------------
resource "aws_security_group" "lambda" {
  name_prefix = "${var.project_name}-lambda-"
  description = "Security group para la funcion Lambda de procesamiento"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-lambda-sg"
  }
}

# Egress hacia Redis, solo puerto 6379
resource "aws_security_group_rule" "lambda_egress_redis" {
  type                     = "egress"
  from_port                = 6379
  to_port                  = 6379
  protocol                 = "tcp"
  security_group_id        = aws_security_group.lambda.id
  source_security_group_id = aws_security_group.redis.id
  description              = "Acceso a Redis en puerto 6379"
}

# Egress HTTPS: necesario para hablar con S3 via VPC endpoint y, via NAT, con
# otros servicios de AWS (ej. CloudWatch Logs) e internet en general
resource "aws_security_group_rule" "lambda_egress_https" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.lambda.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "HTTPS hacia AWS (S3 via VPC endpoint, CloudWatch Logs) e internet via NAT"
}

# -----------------------------------------------------------------------------
# Security Group de Redis (ElastiCache)
# No tiene reglas propias: las reglas de entrada/salida se agregan abajo como
# recursos independientes, para que cada una sea fácil de leer por separado.
# -----------------------------------------------------------------------------
resource "aws_security_group" "redis" {
  name_prefix = "${var.project_name}-redis-"
  description = "Security group para ElastiCache Redis"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-redis-sg"
  }
}

# Redis solo acepta conexiones que vengan del SG de la Lambda, y solo por el puerto 6379
resource "aws_security_group_rule" "redis_ingress_from_lambda" {
  type                     = "ingress"
  from_port                = 6379
  to_port                  = 6379
  protocol                 = "tcp"
  security_group_id        = aws_security_group.redis.id
  source_security_group_id = aws_security_group.lambda.id
  description              = "Acceso Redis solo desde Lambda en puerto 6379"
}

# Redis no necesita salir a internet: limitamos su salida a la propia VPC
resource "aws_security_group_rule" "redis_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.redis.id
  cidr_blocks       = [var.vpc_cidr]
  description       = "Egress restringido a la VPC"
}
