output "runtask_url" {
  description = "The URL of the HTTP API for the HCP Vault Radar run task"
  value       = "http://${aws_lb.hcp_vault_radar.dns_name}"
}
