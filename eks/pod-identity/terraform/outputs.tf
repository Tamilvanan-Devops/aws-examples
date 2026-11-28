output "iam_role_arn" {
  value = aws_iam_role.application.arn
}
output "association_id" {
  value = aws_eks_pod_identity_association.application.association_id
}
