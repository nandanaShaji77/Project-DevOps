## Repo overview

This repository currently contains Terraform code that provisions AWS resources used as a Terraform remote-state backend (S3 bucket) and a DynamoDB table for state locking. The primary Terraform file present is `backend.tf` which:

- Uses the AWS provider pinned to `~> 6.0` and sets `region = "us-east-1"`.
- Declares an S3 bucket named `devops-automation-project-77577-nandana` with versioning and AES256 server-side encryption.
- Declares a DynamoDB global table `devops-automation-project-lock-table-77577-nandana` with a `LockID` string attribute (used for locks).

## Big-picture architecture and intent

- Purpose: create the AWS resources that will hold Terraform state (S3) and handle state locking (DynamoDB).
- Service boundaries: AWS S3 for durable state storage; DynamoDB for locking; Terraform is the orchestration layer.
- Why this structure: standard Terraform remote-state pattern. Note: the repository currently *creates the backend resources themselves* rather than containing an `terraform { backend "s3" { ... } }` block that points to an already-existing backend. That means running `terraform apply` here will create the bucket and lock table.

## Developer workflows (explicit)

- Environment: set AWS credentials in environment variables before running Terraform:
  - `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and optionally `AWS_SESSION_TOKEN`.
- Common commands (PowerShell):
  - Format and validate: `terraform fmt -recursive; terraform validate`
  - Plan: `terraform plan -out tfplan`
  - Apply: `terraform apply tfplan`
  - Init (first run / when provider or backend changes): `terraform init`

Notes: Because this module creates the S3 and DynamoDB backend resources, consider these safe ordering options:
- Bootstrapping: run this repo in a short-lived local workspace or separate bootstrap workspace to create the backend resources first.
- Once the bucket and table exist, you can add a dedicated backend block in other Terraform configs (or here) to use S3+DynamoDB for remote state.

## Project-specific patterns and conventions

- Naming: resources include a suffix like `-77577-nandana`. Preserve that convention when adding related resources.
- Explicit settings seen in `backend.tf`:
  - `provider "aws" { region = "us-east-1" }` — assume `us-east-1` unless changed.
  - `required_providers { aws = { source = "hashicorp/aws" version = "~> 6.0" } }` — be conservative when upgrading provider versions.
  - The S3 `lifecycle { prevent_destroy = false }` block is present (explicitly allowing destroy); be cautious when making destructive changes.

## Integration points & external dependencies

- AWS account credentials and IAM permissions are required to create S3 buckets and DynamoDB tables.
- No CI/CD configuration files were found in the repo root — expect Terraform to be run manually or from external pipelines. If adding CI, ensure secrets (AWS creds) are stored securely.

## Tasks an AI agent can do safely

- Update small terraform settings (tags, region) when explicitly requested and keep provider constraint intact.
- Add `terraform fmt` and `terraform validate` steps to README or CI configs if asked.
- Propose a bootstrap script / README section that documents the exact steps to create backend resources and later enable remote state.

## What I couldn't find (ask the user)

- No README.md or CI configuration present in the repository root. Please confirm preferred CI provider (GitHub Actions, Terraform Cloud, etc.) and any organization naming conventions for S3/DynamoDB resources.
- Confirm if the backend resources should be created from this repo or if they are expected to pre-exist and be referenced by a backend block.

## Quick references (files)

- `backend.tf` — primary file; defines the S3 bucket and DynamoDB global table.

--
If you'd like, I can: (1) add a short bootstrap `README.md` with the exact `terraform init/plan/apply` steps, (2) add a sample backend block for other repos to consume, or (3) open a PR to pin GitHub Actions CI steps that run `terraform fmt` and `terraform validate`.

Please tell me which of those you want next or provide missing CI/account details.
