# -----------------------------------------------------------------------------
# ElastiCache Subnet Group - apunta a las subnets privadas (sin acceso público)
# -----------------------------------------------------------------------------
resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.project_name}-redis-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "${var.project_name}-redis-subnet-group"
  }
}

# -----------------------------------------------------------------------------
# ElastiCache Redis - un solo nodo cache.t3.micro, sin réplicas (para ahorrar
# costo en este ejercicio). La Lambda guarda cada clave con un tiempo de
# expiración (TTL) explícito, así no quedan datos viejos para siempre.
# -----------------------------------------------------------------------------
resource "aws_elasticache_cluster" "main" {
  cluster_id           = "${var.project_name}-redis"
  engine               = "redis"
  engine_version       = var.redis_engine_version
  node_type            = var.redis_node_type
  num_cache_nodes      = 1
  port                 = 6379
  parameter_group_name = "default.redis7"

  subnet_group_name = aws_elasticache_subnet_group.main.name
  security_group_ids = [
    aws_security_group.redis.id,
  ]

  apply_immediately = true

  tags = {
    Name = "${var.project_name}-redis"
  }
}
