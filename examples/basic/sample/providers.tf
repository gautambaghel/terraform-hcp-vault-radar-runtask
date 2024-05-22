terraform {

  cloud {
    organization = "organization_name"
    hostname     = "app.terraform.io"

    workspaces {
      name = "workspace_name"
    }
  }

  required_providers {
    pinecone = {
      source  = "pinecone-io/pinecone"
      version = "0.7.4"
    }
  }
}
