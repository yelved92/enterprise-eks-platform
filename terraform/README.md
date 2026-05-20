# Terraform Infrastructure
## Structure

Each environment is fully self-contained. Run Terraform from: terraform/environments/dev/

## Key Directories
- modules/ - Reusable Terraform modules
- environments/ - Environment-specific configurations (dev, staging, prod)

## How to Run
```powershell / bash
cd terraform/environments/dev
terraform init
terraform plan
terraform apply
```
