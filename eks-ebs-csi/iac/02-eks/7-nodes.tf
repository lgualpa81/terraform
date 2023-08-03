resource "aws_iam_role" "nodes" {
  name = "${var.cluster_name}-node-group-nodes"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "nodes_amazon_eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "nodes_amazon_eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "nodes_amazon_ec2_container_registry_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.nodes.name
}

# data "tls_certificate" "auth" {
#   url = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
# }

# resource "aws_iam_openid_connect_provider" "main" {
#   client_id_list  = ["sts.amazonaws.com"]
#   thumbprint_list = [data.tls_certificate.auth.certificates[0].sha1_fingerprint]
#   url             = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
# }

resource "aws_eks_node_group" "private_nodes" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "${var.cluster_name}-${var.environment}-private-nodes"
  node_role_arn   = aws_iam_role.nodes.arn

  subnet_ids = var.eks_node_group_single_az ? [var.private_subnets[0]] : var.private_subnets

  #disk_size only enable if launch_template is commented
  #disk_size      = var.eks_node_group_disk_size
  capacity_type  = var.eks_node_group_capacity_type
  instance_types = ["${var.eks_node_group_instance_types}"]
  ami_type       = var.eks_node_group_arm_architecture ? "AL2_ARM_64" : "AL2_x86_64"

  #launch_template only enable if disk_size is commented
  launch_template {
    name    = aws_launch_template.eks-with-disks.name
    version = aws_launch_template.eks-with-disks.latest_version
  }

  scaling_config {
    desired_size = var.eks_node_group_scaling_desired_size
    max_size     = var.eks_node_group_scaling_max_size
    min_size     = var.eks_node_group_scaling_min_size
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    role = "general"
  }

  depends_on = [
    aws_iam_role_policy_attachment.nodes_amazon_eks_worker_node_policy,
    aws_iam_role_policy_attachment.nodes_amazon_eks_cni_policy,
    aws_iam_role_policy_attachment.nodes_amazon_ec2_container_registry_read_only,
  ]
}

resource "aws_launch_template" "eks-with-disks" {
  name = "eks-with-disks"

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = var.eks_node_group_disk_size
      volume_type = "gp3"
    }
  }
}
