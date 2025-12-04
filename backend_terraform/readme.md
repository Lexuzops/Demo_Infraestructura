# Prueba DevOps - Gestión del State con Terraform

## Estrategia de state

El proyecto usa un **backend remoto** con:

- **S3** para almacenar el archivo `terraform.tfstate`
- **DynamoDB** para locking distribuido (evita applies simultáneos que corrompen el state)

## Stack de bootstrap (backend_terraform)

Los recursos de soporte (bucket S3 + tabla DynamoDB) se crean **solo una vez**, en un stack separado (`backend_terraform/`), porque:

- Evita dependencias circulares
- Protege el state contra ejecución concurrente
- Permite colaboración segura entre pipelines o equipos

# Migración del state

Una vez se tiene la infraestructura en local y se quiere migrar para un s3 de amazon, hay que ubicarse en (`infraestructure/`)

y ejecutar: `terraform -migrate-state`

Hay que tener en cuenta que hay que tener la configuracion dentro el main.tf

```hcl
terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket         = "app-test-terraform-state-1234567890"
    key            = "env/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```
