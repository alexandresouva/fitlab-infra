variable "aws_region" {
  type        = string
  description = "AWS region where resources will be provisioned"
  default     = "us-east-1"
}

variable "project_name" {
  type        = string
  description = "Name of the project"
  default     = "fitlab"
}

variable "environment" {
  type        = string
  description = "Environment identifier (e.g. dev, staging, prod)"
  default     = "dev"
}

variable "micro_frontends" {
  type        = list(string)
  description = "List of remote Micro Frontends to provision"
  default     = ["workouts"]
}
