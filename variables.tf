variable "profile" {
  default = "default"
}

variable "eks_cluster_name" {
  type = string
}

variable "region" {
  type = string
}

variable "vpc_name" {
  type = string
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "nat_gateway_scenario" {
  type = string
  description = "Choices: single, one_per_subnet, one_per_azs"
}
