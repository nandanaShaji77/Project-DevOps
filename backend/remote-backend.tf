terraform {
  backend "s3" {
    bucket         = "devops-automation-project-77577-nandana"
    key            = "terraform/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "devops-automation-project-lock-table-77577-nandana"
    encrypt        = true
  }
}
