provider "aws" {
  version = ">= 2.28.1"
  region  = var.region
  profile = var.profile
}

data "aws_availability_zones" "available" {}

locals {
  cluster_name = "${var.eks_cluster_name}-${random_string.suffix.result}"
  azs_names = data.aws_availability_zones.available.names
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}

resource "aws_eip" "nat" {
  vpc = true
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.6.0"

  name = var.vpc_name
  cidr = var.vpc_cidr
  azs  = local.azs_names

  private_subnets = [
    for num in range(1, length(local.azs_names) + 1) : cidrsubnet(var.vpc_cidr, 8, num)
  ]
  public_subnets = [
    for num in range(length(local.azs_names) + 1, length(local.azs_names) * 2 + 1) : cidrsubnet(var.vpc_cidr, 8, num)
  ]

  enable_nat_gateway   = true
  enable_dns_hostnames = true

  single_nat_gateway   = var.nat_gateway_scenario == "single" ? true : false
  one_nat_gateway_per_az = var.nat_gateway_scenario == "one_per_azs" ? true : false

  reuse_nat_ips       = true 
  external_nat_ip_ids = "${aws_eip.nat.*.id}"

  tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }
}
