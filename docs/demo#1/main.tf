terraform {
  required_providers {
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = "=0.1.5"
    }
  }
}

resource "azuredevops_project" "default" {
  name               = "DotNet_Community_How_to_Terraform"
  description        = "Demo project for .NetCommunity"
  visibility         = "private"
  version_control    = "Git"
  work_item_template = "Scrum"
}

resource "azuredevops_git_repository" "repository-1" {
  project_id = azuredevops_project.default.id
  name       = "How_to_Terraform_Git_I"
  initialization {
    init_type = "Clean"
  }
}

resource "azuredevops_git_repository" "repository-2" {
  project_id = azuredevops_project.default.id
  name       = "How_to_Terraform_Git_II"
  initialization {
    init_type = "Clean"
  }
}
