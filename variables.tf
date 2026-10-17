variable "aws_region" {
  description = "AWS region in which the project infrastructure is deployed."
  type        = string
  default     = "eu-west-2"
}

variable "project_name" {
  description = "Name used to identify project resources."
  type        = string
  default     = "msc-ecommerce"
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "presentation"
}

variable "instance_type" {
  description = "EC2 instance type used by the traditional baseline."
  type        = string
  default     = "t3.micro"
}

variable "asg_min_size" {
  description = "Minimum EC2 capacity for the traditional baseline."
  type        = number
  default     = 1
}

variable "asg_desired_capacity" {
  description = "Initial desired EC2 capacity."
  type        = number
  default     = 1
}

variable "asg_max_size" {
  description = "Maximum EC2 capacity."
  type        = number
  default     = 3
}

variable "asg_cpu_target" {
  description = "Target average CPU utilisation percentage for EC2 Auto Scaling."
  type        = number
  default     = 50
}

variable "instance_warmup_seconds" {
  description = "Warm-up period before a new EC2 instance contributes to scaling metrics."
  type        = number
  default     = 300
}
