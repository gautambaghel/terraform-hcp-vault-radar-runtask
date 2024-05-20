output "shell_output" {
  description = "Output by the executed shell command"
  value       = local_file.setenvvars.content
}
