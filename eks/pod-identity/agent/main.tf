# Cluster-wide prerequisite. Import existing EKS add-on or endpoint into this state
# rather than creating duplicate resources.
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 5.0" }
  }
}
provider "aws" { region = var.aws_region }
resource "aws_eks_addon" "pod_identity_agent" {
  cluster_name = var.cluster_name
  addon_name   = "eks-pod-identity-agent"
  # Pin a reviewed EKS-compatible addon_version in real environments.
}
resource "aws_vpc_endpoint" "eks_auth" {
  count               = var.enable_auth_endpoint ? 1 : 0
  vpc_id              = var.vpc_id
  service_name        = format("com.amazonaws.%s.eks-auth", var.aws_region)
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.endpoint_subnet_ids
  security_group_ids  = var.endpoint_security_group_ids
  private_dns_enabled = true
  tags = { Name = format("%s-eks-auth", var.cluster_name) }
}
variable "aws_region" { type = string }
variable "cluster_name" { type = string }
variable "enable_auth_endpoint" {
  type = bool
  default = false
}
variable "vpc_id" {
  type = string
  default = null
}
variable "endpoint_subnet_ids" {
  type = list(string)
  default = []
}
variable "endpoint_security_group_ids" {
  type = list(string)
  default = []
}
output "agent_addon_id" { value = aws_eks_addon.pod_identity_agent.id }
output "auth_vpc_endpoint_id" {
  value = var.enable_auth_endpoint ? aws_vpc_endpoint.eks_auth[0].id : null
}
