# SOAT13 Revenda - database infrastructure

Terraform configuration for three isolated, private MySQL RDS instances used by
the Clientes, Veiculos, and Vendas services. RDS is reachable only from the EKS
worker security group. The VPC, private subnets, and worker security group are
discovered by their AWS tags, so the stack does not depend on Terraform outputs
from `soat13-tc-revenda-infra-k8s`.

## Prerequisites

- AWS CLI profile `default` configured locally in `~/.aws/credentials`; never
  commit credentials to this repository.
- Terraform >= 1.9 and an S3 bucket for encrypted, versioned Terraform state.
- The VPC, private subnets, and EKS worker security group from `infra-k8s` must
  exist in the same AWS account and region, with the expected project tags.

Create `terraform.tfvars` from the example. RDS generates a separate master
password for each database and manages each one in AWS Secrets Manager. The
deployment script reads each secret without printing it:

```sh
cp terraform.tfvars.example terraform.tfvars
export AWS_PROFILE=default
terraform init \
  -backend-config="bucket=<state-bucket>" \
  -backend-config="key=infra-db/terraform.tfstate" \
  -backend-config="region=us-east-1" \
  -backend-config="use_lockfile=true"
terraform plan
terraform apply
```

RDS manages the passwords in Secrets Manager, so they are not stored in
Terraform state. Protect the state bucket with encryption, versioning, and
public-access blocking, and restrict access to the secrets. Do not commit
`terraform.tfvars` or state files. Each database uses a small single-AZ
instance by default; review AWS pricing and availability requirements before
applying. Deletion protection and final snapshots are enabled.

Outputs `db_hosts`, `db_names`, and `db_master_secret_arns` are consumed by the
Kubernetes deploy script. The RDS instances are private and are not exposed to
the internet.

## Data protection and operational limits

Each service has its own MySQL instance and database. RDS storage is encrypted,
automated backups are retained for seven days by default, deletion protection
is enabled, and Terraform requests a final snapshot on deletion. The default
instances are single-AZ; use Multi-AZ and test database restoration when the
availability and recovery objectives require them.

The database security group permits MySQL only from the EKS worker security
group. This is a network boundary, not application-level authorization; limit
Kubernetes access and consider per-workload network controls. Database
credentials are generated and managed by RDS/Secrets Manager. The deployment
script currently copies them into Kubernetes Secrets to initialize the schema
and run the services, so access to the EKS API and its Secret objects must also
be restricted.

## Repositories and report

- [Clientes](https://github.com/mgustavocoder/soat13-tc-revenda-clientes)
- [Veículos](https://github.com/mgustavocoder/soat13-tc-revenda-veiculos)
- [Vendas](https://github.com/mgustavocoder/soat13-tc-revenda-vendas)
- [Infraestrutura EKS e API Gateway](https://github.com/mgustavocoder/soat13-tc-revenda-infra-k8s)
- [Arquitetura, segurança e Saga (PDF)](https://github.com/mgustavocoder/soat13-tc-revenda-infra-k8s/blob/main/docs/arquitetura-seguranca-saga.pdf)
