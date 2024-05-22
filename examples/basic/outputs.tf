output "hcp_tf_org_name" {
  value       = data.tfe_organization.hcp_tf_org.name
  description = "The name of the HCP Terraform organization"
}

output "hcp_tf_workspace_name" {
  value       = tfe_workspace.run_task_workspace.name
  description = "The name of the HCP Terraform workspace with attached run task"
}

output "run_task_url" {
  value       = module.radar_runtask.runtask_url
  description = "The URL of the run task"
}
