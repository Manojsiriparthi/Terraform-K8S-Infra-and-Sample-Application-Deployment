# ============================================================================
# EKS ADDONS OUTPUTS
# ============================================================================

output "oidc_provider_arn" {
  description = "OIDC provider ARN"
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "ebs_csi_role_arn" {
  description = "EBS CSI driver IAM role ARN"
  value       = aws_iam_role.ebs_csi.arn
}

output "aws_lb_controller_role_arn" {
  description = "AWS Load Balancer Controller IAM role ARN"
  value       = aws_iam_role.aws_lb_controller.arn
}

output "cluster_autoscaler_role_arn" {
  description = "Cluster Autoscaler IAM role ARN"
  value       = aws_iam_role.cluster_autoscaler.arn
}

output "cloudwatch_observability_role_arn" {
  description = "CloudWatch Observability IAM role ARN"
  value       = aws_iam_role.cloudwatch_observability.arn
}

output "fluent_bit_role_arn" {
  description = "Fluent Bit IAM role ARN"
  value       = aws_iam_role.fluent_bit.arn
}

output "cloudwatch_log_groups" {
  description = "CloudWatch log groups for EKS cluster"
  value = {
    application = aws_cloudwatch_log_group.application.name
    dataplane   = aws_cloudwatch_log_group.dataplane.name
  }
}

output "external_dns_role_arn" {
  description = "External DNS IAM role ARN"
  value       = aws_iam_role.external_dns.arn
}

output "cert_manager_role_arn" {
  description = "Cert Manager IAM role ARN"
  value       = aws_iam_role.cert_manager.arn
}
