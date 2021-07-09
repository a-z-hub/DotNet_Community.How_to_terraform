# Provider [azuredevops](https://registry.terraform.io/providers/microsoft/azuredevops/latest/docs)

## Precondition:
[authentication](https://registry.terraform.io/providers/microsoft/azuredevops/latest/docs/guides/authenticating_using_the_personal_access_token)

## Terminal:
```
terraform init
terraform validate
terraform plan -out=plan.out -refresh=true
terraform apply plan.out
terraform destroy -auto-approve
```

## Information
[azuredevops](https://registry.terraform.io/providers/microsoft/azuredevops/latest)
[azuredevops_project](https://registry.terraform.io/providers/microsoft/azuredevops/latest/docs/resources/project)
[azuredevops_git_repository](https://registry.terraform.io/providers/microsoft/azuredevops/latest/docs/resources/git_repository)