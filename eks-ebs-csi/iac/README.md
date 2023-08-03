## AWS

1. configurar credenciales

```bash
# NAME es el nombre del perfil por ejemplo iac-tf
$ aws configure --profile NAME 
AWS Access Key ID [None]: your_access_key
AWS Secret Access Key [None]: your_secret_key
Default region name [None]: us-east-1
Default output format [None]: json
```

2. Confirmar creación perfil. **Ej: iac-tf**

```bash
$ cat ~/.aws/credentials              
# output
[iac-tf]
aws_access_key_id = your_access_key
aws_secret_access_key = your_secret_key
```

[referencia]: (https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html)
<a href="https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html">referencia</a>

### IAM permisos para terraform

Policy: **AmazonEKSAdminPolicy**

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "eks:*",
                "ec2:*",
                "logs:*",
                "iam:AttachRolePolicy",
                "iam:CreateRole",
                "iam:CreatePolicy",
                "iam:PutRolePolicy",
                "iam:GetPolicy",
                "iam:GetRole",
                "iam:ListRolePolicies",
                "iam:GetPolicyVersion",
                "iam:GetRolePolicy",
                "iam:ListAttachedRolePolicies",
                "iam:TagRole",
                "iam:DetachRolePolicy",
                "iam:ListPolicyVersions",
                "iam:DeletePolicy",
                "iam:ListInstanceProfilesForRole",
                "iam:DeleteRole",
                "iam:DeleteRolePolicy",
                "iam:CreateOpenIDConnectProvider",
                "iam:TagOpenIDConnectProvider",
                "iam:UntagOpenIDConnectProvider",
                "iam:GetOpenIDConnectProvider",
                "iam:DeleteOpenIDConnectProvider",
                "iam:ListEntitiesForPolicy",
                "iam:CreatePolicyVersion",
                "iam:DeletePolicyVersion"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "iam:PassRole",
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "iam:PassedToService": [
                        "eks.amazonaws.com",
                        "ec2.amazonaws.com",
                        "iam.amazonaws.com",
                        "logs.amazonaws.com"
                    ]
                }
            }
        }
    ]
}
```

Rol: **IaCEKSAdminRole**

Permissions attach AmazonEKSAdminPolicy

Trusted entities

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::account_id:root"
            },
            "Action": "sts:AssumeRole",
            "Condition": {}
        }
    ]
}
```

Policy assume role: **AmazonEKSAssumeEKSAdminPolicy**

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sts:AssumeRole"
            ],
            "Resource": "arn:aws:iam::account_id:role/IaCEKSAdminRole"
        }
    ]
}
```

## Estructura proyecto terraform

Detalle:

```bash
- main.tf, punto de entrada y referencia a los módulos 01-vpc y 02-eks
- variable.tf, parámetros para configurar cluster
- módulo 01-vpc/, configura la infraestructura (vpc, cidr, subnets) para usar EKS.
- módulo 02-eks/, configura EKS (nodos, tamaño discos EBS, permisos)
- directorio envs/, contiene la configuración del backend remoto (bucket S3) y cluster por ambiente (dev, qa, uat, etc)
```

```bash
├── 01-vpc
│   ├── 1-vpc.tf
│   ├── 2-igw.tf
│   ├── 3-subnets.tf
│   ├── 4-nat.tf
│   ├── 5-routes.tf
│   ├── output.tf
│   └── variable.tf
├── 02-eks
│   ├── 10-csi-driver-addon.tf
│   ├── 6-eks.tf
│   ├── 7-nodes.tf
│   ├── 8-iam-oidc.tf
│   ├── 9-csi-driver-iam.tf
│   ├── output.tf
│   └── variable.tf
├── envs
│   ├── backend-dev.hcl
│   ├── backend-qa.hcl
│   ├── backend-uat.hcl
│   ├── dev.tfvars
│   ├── qa.tfvars
│   └── uat.tfvars
├── main.tf
├── README.md
└── variable.tf
```

Usar las plantillas con extension **.template** (*backend-env.hcl.template* y *env.tfvars.template*) que corresponden al backend remoto y al entorno del cluster (dev|qa|uat|prod). Estas plantillas sirven como base para la configuración de los recursos a ser aprovisionados.

### Se sugiere sacar una copia y renombrarlos según el entorno omitiendo la extensión '**.template**'


Ejemplo configuración para entorno: **qa**
### Pasos
1. Renombrar archivos
- backend-**qa**.hcl
- **qa**.tfvars

2. Configuración archivo *backend-qa.hcl* 

```bash
bucket                  = "eks_tf_persistent_states"
shared_credentials_file = "~/.aws/credentials"
profile                 = "iac-tf"
key                     = "global/eks/tf-workspaces/qa.tfstate"
region                  = "us-east-1"
encrypt                 = true
```

**NOTA:** No es necesario tener varios buckets por entorno a configurar, se puede reutilizarlo y variar en la ruta del directorio (*atributo key*)

3. Configuración archivo *qa.tfvars* 

```bash
aws_region                          = "us-east-1"
aws_profile                         = "iac-tf"
environment                         = "qa"
cluster_name                        = "main-tf"
vpc_cidr                            = "192.168.0.0/16"
vpc_name                            = "main"
public_subnets_cidr                 = ["192.168.0.0/24", "192.168.1.0/24"]
private_subnets_cidr                = ["192.168.4.0/24", "192.168.5.0/24"]
availability_zones_public           = ["us-east-1a", "us-east-1b"]
availability_zones_private          = ["us-east-1a", "us-east-1b"]
cidr_block-internet_gw              = "0.0.0.0/0"
cidr_block-nat_gw                   = "0.0.0.0/0"
eks_node_group_single_az            = true
eks_node_group_arm_architecture     = false
eks_node_group_instance_types       = "t2.medium"
eks_node_group_capacity_type        = "SPOT"
eks_node_group_disk_size            = 20
eks_node_group_scaling_desired_size = 2
eks_node_group_scaling_max_size     = 3
eks_node_group_scaling_min_size     = 0
```

Para configurar otros ambientes (dev|uat|prod) seguir los Pasos 1,2,3

## Terraform comandos

En el directorio **iac/envs** están los archivos de configuración del backend remoto y cluster por entorno *(dev, qa, uat, prod)* previamente parametrizados.

```bash
# preparar dependecias y referenciar a backend remoto
terraform init -backend-config=envs/backend-qa.hcl
# reconfigurar dependencias
terraform init -backend-config=envs/backend-qa.hcl -reconfigure
# preparar los recursos a aprovisionar
terraform plan -var-file=envs/qa.tfvars
# aprovisionar recursos
terraform apply -var-file=envs/qa.tfvars
# aprovisionar recursos de un módulo específico
terraform apply -var-file=envs/qa.tfvars -target=module.eks
# destruir recursos
terraform destroy -var-file=envs/qa.tfvars
# destruir recursos de un módulo específico
terraform destroy -var-file=envs/qa.tfvars -target=module.eks
```

## EKS

Agregar cluster a **kubeconfig** (kubernetes)

```bash
$ aws eks update-kubeconfig --region us-east-1 --name mycluster --profile iac-tf
```
[referencia]: (https://docs.aws.amazon.com/eks/latest/userguide/create-kubeconfig.html)
<a href="https://docs.aws.amazon.com/eks/latest/userguide/create-kubeconfig.html">referencia</a>