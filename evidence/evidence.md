# Evidencia del despliegue y la prueba

En esta carpeta están las capturas que muestran que el proyecto quedó funcionando en AWS y que la caché responde como se espera: primero MISS, luego HIT.

## Las 3 capturas principales

Estas son las que más importan, porque muestran el flujo completo que pide el ejercicio:

1. **`1.RequestconXCache MISS(primera llamada).png`**
   Es la primera vez que se llama a la API. Como todavía no hay nada guardado en la caché, la respuesta llega con el header `X-Cache: MISS`,
   o sea que la Lambda tuvo que procesar todo desde cero.

2. **`2.Mismo requestcon XCacheHIT (segundallamada).png`**
   Aquí se repite exactamente la misma petición. Esta vez la respuesta trae
   `X-Cache: HIT`, lo que significa que la Lambda encontró el resultado ya guardado en Redis y no tuvo que procesar nada de nuevo.

3. **`3.objetoGuardado en S3(salida de aws s3 ls ocaptura).png`**
   Muestra que, durante esa primera llamada (el MISS), el resultado también quedó guardado en el bucket de S3, dentro de la carpeta `results/`.

## Capturas adicionales


- **`TerraformApplyCompleted.png`** — el `terraform apply` terminó sin errores.
- **`vpcWorks.png`** — la VPC y las subredes quedaron creadas.
- **`sg.png`** — los Security Groups (las reglas de quién puede hablar con  quién).
- **`apiGatewayWorks.png`** — el API Gateway con la ruta `POST /process` lista.
- **`Lambdaworks.png`** — la función Lambda desplegada y configurada.
- **`redisWorks.png`** / **`elasticCacheRedis.png`** — el cluster de Redis activo.
- **`policyAWSLambda.png`** — los permisos (IAM) que tiene la Lambda.
- **`logsAWSCloudWatch.png`** / **`logEventAWSCloud.png`** — los logs que genera la Lambda en CloudWatch.
