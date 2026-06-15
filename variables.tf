variable "aws_region" {
  description = "Región AWS donde se despliega la infraestructura"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefijo usado para nombrar todos los recursos"
  type        = string
  default     = "sre-test"
}

variable "vpc_cidr" {
  description = "CIDR block de la VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDRs de las 2 subnets públicas (una por AZ)"
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDRs de las 2 subnets privadas (una por AZ)"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "availability_zones" {
  description = "Lista de 2 AZs a usar. Si está vacía, se calculan dinámicamente a partir de las AZs disponibles en la región."
  type        = list(string)
  default     = []
}

variable "redis_node_type" {
  description = "Tipo de instancia para ElastiCache Redis"
  type        = string
  default     = "cache.t3.micro"
}

variable "redis_engine_version" {
  description = "Versión del motor Redis"
  type        = string
  default     = "7.1"
}

variable "lambda_runtime" {
  description = "Runtime de la función Lambda"
  type        = string
  default     = "python3.12"
}

variable "lambda_timeout" {
  description = "Timeout de la función Lambda en segundos"
  type        = number
  default     = 10
}

variable "lambda_memory_size" {
  description = "Memoria asignada a la función Lambda en MB"
  type        = number
  default     = 128
}

variable "cache_ttl_seconds" {
  description = "TTL en segundos para las keys de caché en Redis"
  type        = number
  default     = 60
}

variable "api_throttling_rate_limit" {
  description = "Rate limit (requests/segundo) a nivel de stage de API Gateway"
  type        = number
  default     = 10
}

variable "api_throttling_burst_limit" {
  description = "Burst limit a nivel de stage de API Gateway"
  type        = number
  default     = 20
}

variable "log_retention_days" {
  description = "Días de retención de logs en CloudWatch"
  type        = number
  default     = 7
}
