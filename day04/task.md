Task 1: Why State Matters
=========================

1. What is the terraform.tfstate file and what does it store?
-------------------------------------------------------------
The terraform.tfstate file is Terraform's state file. it keeps a record of the infrastructure that Terraform managers and maps the resouces defined in your configuration to the real resources in your cloud provider or other platform.
It stores information such as:


Resource IDs and metadata.
Current values of resource attributes.
Resource dependencies.
Outputs defined in the Terraform configuration.
Provider and module information

Terraform uses this file to determine:

What infrastructure already exists.
What changes are needed to reach the desired configuration.
Which resources need to be created, updated, or destroyed.

2. Why should you never edit it by hand or commit it to Git?
===========================================================
Do not edit it manually because:

It can corrupt the state, causing Terraform to lose track of resources.
Incorrect edits may result in failed deployments or accidental deletion and recreation of infrastructure.
Terraform expects the state to remain internally consistent.
Do not commit it to Git because:

It may contain sensitive information such as passwords, API keys, tokens, private IPs, or other secrets.
State files change frequently, creating unnecessary merge conflicts.
Exposing the file in a public or shared repository creates a significant security risk.
Instead, teams typically use a remote backend (such as AWS S3 with state locking via DynamoDB, Terraform Cloud, or Azure Storage) to securely store and manage state.


3. What is state drift, and how do terraform plan and terraform refresh relate to it?
State drift occurs when the actual infrastructure differs from what Terraform's state file expects. This usually happens when someone manually changes resources outside of Terraform (for example, through the cloud provider's console or CLI).

Examples of drift:

A VM is resized manually.
A security group rule is changed in the cloud console.
A resource is deleted outside Terraform.
terraform plan

Compares the Terraform configuration, the current state, and the actual infrastructure.
Detects differences and shows what actions Terraform would take to bring the infrastructure back to the desired state

terraform refresh

Updates the state file with the current information from the real infrastructure without changing the infrastructure itself.
This helps synchronize the state with resources that have changed outside Terraform.
In modern Terraform versions, terraform plan automatically performs a refresh by default, so running terraform refresh separately is usually unnecessary.

4. Why is the state sensitive (it can contain secrets in plaintext)?
The Terraform state file may contain sensitive data because it stores the actual values of resource attributes after creation.

Examples of sensitive information that may appear include:

Database usernames and passwords.
API keys and access tokens.
Cloud credentials.
Private IP addresses.
Connection strings.
TLS certificates or private keys (depending on the provider).
Even if Terraform marks outputs or variables as sensitive, their values may still be stored in the state file. Because of this, the state file should be:

Stored securely (preferably in an encrypted remote backend).

Protected with strict access controls.
Excluded from version control using .gitignore.
Accessible only to authorized users and systems.


Task 2: Explore Local State & terraform state
After running terraform apply, the following commands help inspect and manage Terraform state.

1. terraform state list
Command:

terraform state list

What it does
Lists all resources currently tracked in the Terraform state file.

Example output
aws_instance.web
aws_security_group.web_sg
aws_s3_bucket.logs


When to use it
See which resources Terraform is managing.
Find the correct resource address for other terraform state commands.
Verify resources after an import or apply.
2. terraform state show <resource_address>
Command:

terraform state show aws_instance.web

What it does
Displays detailed information about a specific resource stored in the state file.

Example output
# aws_instance.web:
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t2.micro"
  id            = "i-0123456789abcdef0"
  private_ip    = "10.0.1.15"
}

When to use it
Inspect the current attributes of a resource.
Verify IDs, IP addresses, or other stored values.
Troubleshoot resource configuration.



3. terraform state mv <src> <dest>
Command:

terraform state mv aws_instance.web aws_instance.app

What it does
Moves or renames a resource within the Terraform state without recreating the actual infrastructure.

When to use it
Rename a resource block.
Move a resource into or out of a module.
Refactor Terraform code without destroying existing resources.
Example
Before:

resource "aws_instance" "web" {}

After renaming:

resource "aws_instance" "app" {}

Instead of destroying and recreating the instance, run:

terraform state mv aws_instance.web aws_instance.app



4. terraform state rm <resource_address>
Command:

terraform state rm aws_instance.web

What it does
Removes a resource from Terraform's state without deleting the actual infrastructure.

When to use it
Stop Terraform from managing a resource.
Prepare to import the resource into another state.
Remove accidentally imported resources.
Important
The infrastructure still exists.
Terraform simply "forgets" about it.
A future terraform apply may attempt to create a new resource if it is still defined in the configuration.
5. terraform show
Command:

terraform show

What it does
Displays the current Terraform state in a human-readable format.

Example output



# aws_instance.web:
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t2.micro"
}

When to use it
Review the current infrastructure managed by Terraform.
Verify resource attributes and outputs.
Debug or inspect the state file without opening the raw terraform.tfstate JSON file.





