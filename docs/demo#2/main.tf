data "azuredevops_project" "imported-default" {
  name = "DotNet_Community_How_to_Terraform"
}

# Load a specific Git repository by name
data "azuredevops_git_repository" "imported-repository-1" {
  project_id = data.azuredevops_project.imported-default.id
  name       = "How_to_Terraform_Git_I"
}

data "azuredevops_git_repository" "imported-repository-2" {
  project_id = data.azuredevops_project.imported-default.id
  name       = "How_to_Terraform_Git_II"
}

terraform {
  required_providers {
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = "=0.1.5"
    }
  }
}

resource "azuredevops_branch_policy_min_reviewers" "min-2-reviewers" {
  project_id = data.azuredevops_project.imported-default.id

  enabled  = true
  blocking = true

  settings {
    reviewer_count                         = 2
    submitter_can_vote                     = false
    last_pusher_cannot_approve             = true
    allow_completion_with_rejects_or_waits = false
    on_push_reset_all_votes                = true
    on_last_iteration_require_vote         = false

    scope {
      repository_id  = data.azuredevops_git_repository.imported-repository-1.id
      repository_ref = data.azuredevops_git_repository.imported-repository-1.default_branch
      match_type     = "Exact"
    }

    scope {
      repository_id  = data.azuredevops_git_repository.imported-repository-2.id
      repository_ref = data.azuredevops_git_repository.imported-repository-2.default_branch
      match_type     = "Exact"
    }
  }
}

resource "azuredevops_branch_policy_merge_types" "limit-merge-types" {
  project_id = data.azuredevops_project.imported-default.id

  enabled  = true
  blocking = true

  settings {
    allow_squash                  = false
    allow_rebase_and_fast_forward = true
    allow_basic_no_fast_forward   = true
    allow_rebase_with_merge       = false

    scope {
      repository_id  = data.azuredevops_git_repository.imported-repository-1.id
      repository_ref = data.azuredevops_git_repository.imported-repository-1.default_branch
      match_type     = "Exact"
    }

    scope {
      repository_id  = data.azuredevops_git_repository.imported-repository-2.id
      repository_ref = data.azuredevops_git_repository.imported-repository-2.default_branch
      match_type     = "Exact"
    }
  }
}

resource "azuredevops_project_features" "project-features" {
  project_id = data.azuredevops_project.imported-default.id
  features = {
    "boards"    = "enabled"
    "pipelines" = "enabled"
    "artifacts" = "enabled"
    "testplans" = "disabled"
  }
}
