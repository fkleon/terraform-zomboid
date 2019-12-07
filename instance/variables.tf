variable "name" {
  type        = string
  default     = "zomboid"
  description = "Prefix to use for resource names."
}

variable "region" {
  type        = string
  default     = "eu-central-1"
  description = "AWS region to create resources in."
}

variable "availability_zone" {
  type        = string
  default     = "eu-central-1b"
  description = "AWS availablility zone to create resources in."
}

variable "tags" {
  type = map(string)
  default = {
    "Project" : "zomboid"
  }
}

variable "instance_type" {
  type        = string
  default     = "t2.micro"
  description = "AWS instance type to use for the Factorio server."
}

variable "ssh_public_key" {
  type        = string
  description = "SSH key to provision into authorized_keys."
}

variable "ssh_private_key" {
  type        = string
  description = "SSH private key to use for file provisioning."
}

variable "bucket_name" {
  type        = string
  description = "S3 bucket to use for save game backups."
}

variable "instance_profile" {
  type        = string
  default     = "zomboid-instance-profile"
  description = "Instance profile to assign to AWS instance. This should be configured to allow access to the S3 backup bucket."
}

variable "zomboid_app_id" {
  type        = string
  default     = "380870"
  description = "Steam AppID of the Project Zomboid Dedicated Server."
}

variable "admin_password" {
  type        = string
  description = "Zomboid server admin password"
}
