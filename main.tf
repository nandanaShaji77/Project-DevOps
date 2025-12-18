terraform{
    required_providers {
        aws ={
            source = "hashicorp/aws"
            version = "~>6.0"
        }
}
backend "s3" {
        bucket = "devops-automation-project-77577-nandana"
        key    = "path/to/my/terraform.tfstate"
        region = "us-east-1"
        use_lockfile = true
        encrypt = true
    }
}
provider "aws" {
    region = "us-east-1"
}

resource "aws_vpc" "main" {
    cidr_block = "10.1.0.0/16" 
    enable_dns_support = true
    enable_dns_hostnames = true
    tags = {
        Name = "main-vpc-project" 
}
}