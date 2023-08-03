variable "cluster_name" {
  description = "the name of your stack, e.g. \"demo\""
}

variable "environment" {
  description = "the name of your environment, e.g. \"prod\""
}

variable "eks_node_group_single_az" {
  description = "One availability_zone"
}

variable "eks_node_group_arm_architecture" {
  description  = "Set arm architecture of node group"
}

variable "eks_node_group_instance_types" {
  description  = "Instance type of node group"
}

variable "eks_node_group_capacity_type" {
  description  = "Capacity type of node group: ON-DEMAND, SPOT"
}

variable "eks_node_group_disk_size" {
  description  = "Disk size of node group"
}

variable "eks_node_group_scaling_desired_size" {
  description = "Scaling desired size for nodes"
}

variable "eks_node_group_scaling_max_size" {
  description = "Scaling max size for nodes"
}
variable "eks_node_group_scaling_min_size" {
  description = "Scaling min size for nodes"
}

variable "private_subnets" {
  description = "List of private subnet IDs"
}

variable "public_subnets" {
  description = "List of private subnet IDs"
}
