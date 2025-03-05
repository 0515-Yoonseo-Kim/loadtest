variable "ami_id" {
  description = "The AMI ID for the EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "The instance type for the EC2 instance"
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "The name of the SSH key pair"
  type        = string
}


variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the load balancer"
  type        = list(string)
}

variable "environment" {
  description = "Environment (dev/prod)"
  type        = string
}

variable "route53_zone_id" {
  description = "The ID of the Route 53 hosted zone"
  type        = string
}

variable "eip" {
  description = "Elastic IP Allocation"
  type        = string
}

variable "domain" {
  description = "Domain name"
}