variable "region" {
  description = "AWS region used by the application infrastructure."
  type        = string
  default     = "us-east-1"
}

variable "tf_state_bucket" {
  description = "S3 bucket containing the infra-k8s Terraform state."
  type        = string
}

variable "master_username" {
  description = "Master username shared by the isolated service databases."
  type        = string
  sensitive   = true
}

variable "master_password" {
  description = "Master password for the isolated service databases."
  type        = string
  sensitive   = true
}

variable "instance_class" {
  description = "RDS instance class for each microservice database."
  type        = string
  default     = "db.t4g.micro"
}

variable "allocated_storage_gib" {
  description = "Initial encrypted gp3 storage per database instance."
  type        = number
  default     = 20
}

variable "backup_retention_days" {
  description = "Automated backup retention period."
  type        = number
  default     = 7
}
