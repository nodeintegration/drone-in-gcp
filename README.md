# Spins up a basic drone ci/cd system on google cloud with drone autoscaler

## Requirements
  - google cloud account (with essential project ownership rights)
  - gke project created

## Setup
  - fill out the appropriate terraform.tfvars in project root
  - export GOOGLE_APPLICATION_CREDENTIALS="/path/to/creds.json"
  - terraform init terraform-drone/
  - terraform plan terraform-drone/
  - terraform apply terraform-drone/


## Notes
  - This is not meant to be run in production but rather give you a quick base to get up and running
  - It relies on local terraform state which is ignored from git
  - It relies on drones database being in the default sql lite database on a persistent disk
