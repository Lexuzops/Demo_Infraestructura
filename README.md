
# Supuestos de Infraestructura

Este documento describe los **supuestos de diseño de la infraestructura** necesaria para desplegar una aplicación **monolítica**, desarrollada de forma que **no puede segmentarse fácilmente en microservicios**.

El objetivo es dejar claro **por qué** se eligió esta arquitectura, **qué componentes** la forman y **cómo se espera que opere** en diferentes entornos.

## Contexto de la aplicación

- La aplicación es **monolítica**:
  - Frontend (HTML/CSS) servido por Nginx.
  - Backend implementado en **Python + Flask**.
- No existe separación lógica clara que permita extraer módulos a microservicios sin cambios profundos de código.
- El modelo de despliegue esperado es **“todo o nada”**:
  se despliega **un único artefacto** (código monolítico) por instancia.

## Supuestos generales

- La infraestructura se define como **Infrastructure as Code (IaC)**, por ejemplo, con Terraform.
- El proveedor cloud asumido es **AWS** (los conceptos pueden extrapolarse a otros proveedores).
- La aplicación se despliega sobre **instancias de cómputo (EC2)** en lugar de:
  - Lambdas / Functions as a Service.
  - Contenedores orquestados (ECS/EKS).
- Se asume que:
  - El equipo de desarrollo **no ha realizado** una separación por dominios/módulos que permita microservicios.
  - El tiempo/esfuerzo de refactorización a microservicios **no es viable** para el alcance de este proyecto.
  - El tráfico esperado es moderado/medio, pero con posibilidad de escalar añadiendo más instancias.

## Infraestructura Terraform

Separar la infraestructura en archivos por servicio (VPC, subredes, ALB, EC2, S3, DynamoDB, IAM, outputs/vars) como está en infraestructure/*.tf ayuda porque:

- Claridad y ownership: cada archivo (vpc.tf, subnets.tf, alb.tf, ec2.tf, s3.tf, dynamodb.tf, roles.tf) contiene un dominio concreto,    así  es fácil que distintos equipos mantengan su pieza sin perderse en un monolito.
- Observabilidad y outputs claros: outputs.tf y variable.tf concentran la interfaz de entrada/salida del stack, evitando que variables o exportaciones queden dispersas.

## Estrategia de Git

Este repositorio sigue un modelo de **trunk-based**

Por qué t**runk-based** y no `dev` / `prod`?  R:// Porque es menos complejo y mas rapido el despliegue

En trunk-based solo hay **una rama principal (`main`)** que siempre está lista para desplegar.

- `main`: rama principal, siempre desplegable. Todo cambio llega a `main` vía Pull Request con CI pasando.
- `feature/*`: ramas para nuevas funcionalidades o cambios no urgentes.
- `hotfix/*`: ramas para correcciones urgentes en producción.

### Flujo de trabajo

1. Crear rama desde `main`:
   - `feature/<descripcion>` para features o bugfixes no urgentes.
   - `hotfix/<descripcion>` para correcciones urgentes.
2. Subir cambios y abrir Pull Request hacia `main`.
3. Esperar a que CI pase (build, tests, terraform plan).
4. Hacer merge a `main` (squash merge).
5. El merge a `main` dispara el pipeline de despliegue.

### Releases

- Se crean tags anotados sobre `main`, por ejemplo:
  - `v1.0.0`, `v1.1.0`, etc.
- Cada tag representa una versión estable desplegable.

## Estrategia de gestión del state de Terraform

### Backend elegido

El proyecto utiliza un **backend remoto en AWS** basado en:

- **S3** para almacenar el `terraform.tfstate`
- **DynamoDB** para gestionar el **locking** del state

Esto permite:

- **Colaboración**: todos los desarrolladores y pipelines usan el mismo estado centralizado.
- **Confiabilidad**: el state no depende de la máquina local y se beneficia de la durabilidad de S3.

### Organización de los archivos de state

El state se organiza por entorno usando la clave (`key`) del backend:

- Bucket: `app-test-terraform-state-1234567890`
- Key: `env/dev/terraform.tfstate`

Esto facilita separar estados por entorno (por ejemplo, `env/dev`, `env/qa`, `env/prod`).

### Mecanismo de locking

Terraform usa la tabla DynamoDB como ***locking*** para el state.
El **locking** evita que dos ejecuciones simultáneas (`apply/plan`) escriban al mismo `terraform.tfstate` y lo corrompan.

**¿Para qué es bueno?**

- **Protección del state**: garantiza que una sola operación pueda modificar el state a la vez.
- **Consistencia de la infraestructura**: evita que cambios incompletos o sobreescrituras de otra ejecución dejen el state en un estado inválido.
- **Depuración**: si un proceso falla y deja el lock pegado, puedes ver en la tabla quién lo tomó y liberarlo manualmente si es necesario.

### Consideraciones de seguridad para el archivo de state.

El archivo `terraform.tfstate` puede contener información sensible (como IDs de recursos, configuraciones, etc.). Por eso

- El bucket S3 debe tener políticas estrictas de acceso (solo usuarios y roles autorizados).
- Bloquear acceso público al bucket S3
- Habilitar el cifrado en reposo (S3 y DynamoDB).
- Habilitar versionado para recuperar state anterior si hay .
- Auditar accesos al bucket S3 y tabla DynamoDB con CloudTrail.

## Decisiones aceleradas y exclusiones de buenas prácticas

- El desarrollo de la aplicación se realizó en **muy poco tiempo**, priorizando que el sistema funcionara “rápido” antes que “bien”.
- Debido a esta limitante, y dado que el equipo destinó la mayor parte del esfuerzo al **diseño, despliegue de infraestructura y la construcción del pipeline CI/CD**, **no se aplican buenas prácticas de despliegue de software**, tales como:
  - Separación por dominios o servicios desacoplados.
  - Manejo robusto de dependencias y configuración inmutable.
  - Empaquetado en artefactos versionados y reproducibles.
  - Estrategias seguras y validadas de autoscaling.

### Exclusión del Auto Scaling Group (ASG)

- Inicialmente se intentó usar un **Auto Scaling Group** para escalado automático de EC2.
- Sin embargo, se detectaron **errores recurrentes en el despliegue cuando la app intentaba autoescalar**:
  - La aplicación falla al inicializar correctamente en nuevas réplicas.
  - Pierde estado o dependencia implícita entre capas al levantar nuevas instancias.
- Dado que **la app no es apta para autoescalado real sin una refactorización profunda**, y considerando que el objetivo principal del proyecto era **avanzar en IaC y CI/CD** se decidio excluirlo.
