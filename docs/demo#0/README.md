source: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/sql_database

```
az login
az account show

terraform init
terraform plan -out current.tfplan
terraform apply current.tfplan
terraform destroy --auto-approve=true
```