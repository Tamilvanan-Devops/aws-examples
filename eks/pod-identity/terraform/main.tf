# Application-scoped role and Pod Identity association.
# The EKS cluster/agent and Kubernetes service account already exist.
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 5.0" }
  }
}
provider "aws" { region = var.aws_region }

data "aws_iam_policy_document" "trust" {
  statement {
    sid     = "ScopedEksPodIdentity"
    effect  = "Allow"
    actions = ["sts:AssumeRole", "sts:TagSession"]
    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/eks-cluster-arn"
      values   = [var.cluster_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/kubernetes-namespace"
      values   = [var.namespace]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/kubernetes-service-account"
      values   = [var.service_account_name]
    }
  }
}
resource "aws_iam_role" "application" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.trust.json
  tags = {
    ManagedBy   = "Terraform"
    Application = var.service_account_name
  }
}
data "aws_iam_policy_document" "permissions" {
  dynamic "statement" {
    for_each = var.policy_statements
    content {
      sid       = statement.value.sid
      effect    = "Allow"
      actions   = statement.value.actions
      resources = statement.value.resources
    }
  }
}
resource "aws_iam_policy" "application" {
  name   = format("%s-permissions", var.role_name)
  policy = data.aws_iam_policy_document.permissions.json
}
resource "aws_iam_role_policy_attachment" "application" {
  role       = aws_iam_role.application.name
  policy_arn = aws_iam_policy.application.arn
}
resource "aws_eks_pod_identity_association" "application" {
  cluster_name    = var.cluster_name
  namespace       = var.namespace
  service_account = var.service_account_name
  role_arn        = aws_iam_role.application.arn
  tags = {
    ManagedBy   = "Terraform"
    Application = var.service_account_name
  }
}
