```
az login
az account show

terraform init
terraform plan -out current.tfplan -var-file="dev.tfvars"
terraform apply current.tfplan
terraform output -json
terraform destroy -var-file="dev.tfvars" -auto-approve=true
```