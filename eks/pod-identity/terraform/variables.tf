variable "aws_region" { type = string }
variable "cluster_name" { type = string }
variable "cluster_arn" { type = string }
variable "namespace" { type = string }
variable "service_account_name" { type = string }
variable "role_name" { type = string }
variable "policy_statements" {
  description = "Application-specific IAM permissions. Review each action/resource."
  type = list(object({
    sid       = string
    actions   = list(string)
    resources = list(string)
  }))
  validation {
    condition = length(var.policy_statements) > 0 && alltrue([
      for p in var.policy_statements :
      length(p.actions) > 0 && length(p.resources) > 0 &&
      !contains(p.actions, "*") && !contains(p.resources, "*")
    ])
    error_message = "Specify non-empty, explicit actions and resources, not wildcard *."
  }
}
