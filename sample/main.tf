terraform {
  cloud {
    organization = "tfc-integration-sandbox"

    workspaces {
      name = "terraform-shell-radar"
    }
  }

  required_providers {
    pinecone = {
      source = "pinecone-io/pinecone"
      version = "0.7.4"
    }
  }
}

# Creating a shell script on the fly
resource "local_file" "setenvvars" {
  filename = "./scripts/setenv.sh"
  content  = <<-EOT
    #!/bin/bash
    export OUTPUT='Hello ${var.random_input}'
    echo $OUTPUT
  EOT
}

# token to be picked up by HashiCorp Vault Radar
provider "pinecone" {
  api_key = "fdfa439d-99ce-4f58-88bb-b4b04e7775d0"
}
