# AWS Basic Web Server using Terraform
This template creates VPC, Internet Gateway, Route Table, Subnet, Security group, and an ubuntu EC2 instance.

Steps:

 1. Make sure Terraform is installed.
 2. AWS access keys must be set-up in your local machine (AWS CLI).
 3. Clone the repository.
 4. Make necessary changes such as the region, cidr block, ami.
 5. Run `terraform plan`
 6. Run `terraform apply` then type `yes` 
 7. To destroy the provisioned resources, run `terraform destroy`

