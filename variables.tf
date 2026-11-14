variable "region" {
  description = "AWS region used by the application infrastructure."
  type        = string
  default     = "us-east-1"
}

variable "master_username" {
  description = "Master username shared by the isolated service databases."
  type        = string
  default     = "application_db_admin"
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
