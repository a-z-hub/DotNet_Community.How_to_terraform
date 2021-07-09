terraform {
  required_providers {
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = "=0.1.5"
    }
  }
}

resource "azuredevops_project" "project" {
  name = "DotNet_Community_How_to_Terraform"
}

resource "azuredevops_git_repository" "repo" {
  project_id = azuredevops_project.project.id
  name       = "How_to_Terraform_Git"
  initialization {
    init_type = "Uninitialized"
  }
}
