provider "aws" {
  region                   = var.aws_region
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = var.aws_profile
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.39"
      #version = "~> 5.4.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  #backend configuration can't use variables data
  # backend "s3" {
  #   bucket                  = "cfv-eks-tf-state"
  #   shared_credentials_file = "~/.aws/credentials"
  #   profile                 = "terraform-cfv"
  #   key                     = "global/eks/tf-workspaces/terraform.tfstate"
  #   region                  = "us-east-1"
  #   encrypt                 = true
  # }

  backend "s3" {}
}

module "vpc" {
  source                     = "./01-vpc"
  environment                = var.environment
  eks_node_group_single_az   = var.eks_node_group_single_az
  vpc_cidr                   = var.vpc_cidr
  vpc_name                   = var.vpc_name
  cluster_name               = var.cluster_name
  public_subnets_cidr        = var.public_subnets_cidr
  availability_zones_public  = var.availability_zones_public
  private_subnets_cidr       = var.private_subnets_cidr
  availability_zones_private = var.availability_zones_private
  cidr_block-nat_gw          = var.cidr_block-nat_gw
  cidr_block-internet_gw     = var.cidr_block-internet_gw
}


module "eks" {
  source                              = "./02-eks"
  cluster_name                        = var.cluster_name
  environment                         = var.environment
  eks_node_group_single_az            = var.eks_node_group_single_az
  eks_node_group_arm_architecture     = var.eks_node_group_arm_architecture
  eks_node_group_instance_types       = var.eks_node_group_instance_types
  eks_node_group_capacity_type        = var.eks_node_group_capacity_type
  eks_node_group_disk_size            = var.eks_node_group_disk_size
  eks_node_group_scaling_desired_size = var.eks_node_group_scaling_desired_size
  eks_node_group_scaling_max_size     = var.eks_node_group_scaling_max_size
  eks_node_group_scaling_min_size     = var.eks_node_group_scaling_min_size
  private_subnets                     = module.vpc.aws_subnets_private
  public_subnets                      = module.vpc.aws_subnets_public
}
