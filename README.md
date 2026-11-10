# SOAT13 Revenda - database infrastructure

Terraform configuration for three isolated, private MySQL RDS instances used by
the Clientes, Veiculos, and Vendas services. RDS is reachable only from the EKS
worker security group exported by `soat13-tc-revenda-infra-k8s`.

## Prerequisites

- AWS CLI authenticated through a local profile or IAM Identity Center; Terraform
  does not accept or store static AWS access keys.
- Terraform >= 1.9 and an S3 bucket for encrypted, versioned Terraform state.
- The `infra-k8s` stack must already be applied to the same AWS account and region.

Create `terraform.tfvars` from the example and provide the database password
only in the environment:

```sh
cp terraform.tfvars.example terraform.tfvars
export AWS_PROFILE=default
export TF_VAR_master_password='use-a-unique-strong-password'
terraform init \
  -backend-config="bucket=<state-bucket>" \
  -backend-config="key=infra-db/terraform.tfstate" \
  -backend-config="region=us-east-1" \
  -backend-config="use_lockfile=true"
terraform plan
terraform apply
```

The password is sensitive but Terraform state still contains it. Protect the
state bucket with encryption, versioning, and public-access blocking. Do not
commit `terraform.tfvars` or state files. Each database uses a small single-AZ
instance by default; review AWS pricing and availability requirements before
applying. Deletion protection and final snapshots are enabled.

Outputs `db_hosts` and `db_names` are consumed by the Kubernetes deploy script.
The RDS instances are private and are not exposed to the internet.
