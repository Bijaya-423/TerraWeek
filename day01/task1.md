Task 1: Understand IaC & Terraform
==================================

1- What is Infrastructure as Code, and what problems does it solve compared to clicking around a cloud console?

-> Infrastructure as Code (IaC) is the practice of provisioning and managing cloud infrastructure (servers, networks, databases) 
using machine-readable definition files rather than manual point-and-click actions. It allows you to treat your infrastructure 
just like application code.

Challenge with CLickOps
-----------------------
- Snowflake Environments: Clicking around means development , testing and production environment are rarely identical.

- Undocumented changes: When someone changes a setting in the console, it's rarely recored . Troubleshooting becomes a nightmare.

- No Version Control: You can't hit ctrl+z on a misconfigured button click in a console

- Human Error: Forgetting to open a port or selecting the wrong instance size is common when deploying manually.

How IaC Solves It
-----------------
- Consistency: Exact copies of your infrastructure can be spun up anywhere , ensuring consistent environment across the board.

- Single Source ot Truth: Your infrastucture is writting out in code files. Every changes is documented, tracked and attributable.

- Version COntrol and ROllbacks: Code is stored in repositories (like git). if an update breaks something, you can immediately rollback to a previous version.

- Automated Validation: Code is reviewed by peers and scanned for errors before it ever touches your cloud environment.

How it Works
------------
- Instead of manually navigating the dashboard , you write a configuration file using specialized syntax in a tool like HashiCorp Terraform or Pulumi. The tool then reads your code, calculates the exact changes required, and communicates with your cloud provider's APIs to build or update your resources automatically.

if you'd like to explore how iac fits into your workflow
---------------------------------------------------------\
- What cloud provider do you primarily use (AWS, Azure, GCP)
- Are you looking to provision new infrastructure , or manage existing resources?


2- What is Terraform, and why is it so popular? (Hint: declarative, provider-agnostic, huge ecosystem.)
====================================================================
- Terraform is an open source infrastructure as code(iac) tool created by HashiCOrp that allows you to define, provision and manage cloud and on premises resources using a human readable configuration language.

📌 Why Terraform is So Popular
===============================

- You only define the desired end-state of your infrastructure.
- Terraform handles the underlying logic to achieve that state.
- It calculates dependencies and creates resources in the correct order.- Modifying infrastructure simply means updating the code and reapplying it



📌 Provider-Agnostic Flexibility
=================================

- It works across multiple cloud vendors using a single workflow.
- You can manage AWS, Azure, Google Cloud, and Oracle simultaneously.
- It prevents absolute lock-in to a single cloud platform's native tools.- Teams only need to learn one tool to manage diverse cloud environments.

📌 Massive Ecosystem and Community
===================================
- Thousands of official and community-built "providers" exist.
- It manages non-cloud resources like Kubernetes, GitHub, and Cloudflare.
- Pre-built, reusable code blocks called "modules" accelerate development.
- A massive community means abundant documentation, tutorials, and troubleshooting help.

📌 Predictable Operations via Execution Plans
==============================================
- The terraform plan command shows exactly what changes will happen.
- It previews resource creation, modification, or deletion before execution.
- This visibility reduces human error and accidental downtime.
- It serves as a safety net for critical infrastructure changes.


📌 State Management Tracking
=============================
- Terraform keeps a record of your real-world infrastructure in a state file.
- This file acts as a single source of truth for your environment.
- It detects configuration drift if someone manually alters a resource.
- It maps your code directly to the actual components running in the cloud.



3- Terraform vs alternatives — write one line each on how Terraform compares to OpenTofu, Pulumi, CloudFormation, and Ansible.
====================================================================
- Terraform is an industry-standard Infrastructure as Code (IaC) tool that relies on a declarative domain-specific language (HCL) to provision and manage cloud resources across multiple providers

- OpenTofu: A fully open-source fork of Terraform that acts as a direct, drop-in replacement, created to maintain open governance and support built-in state encryption.

- Pulumi: Allows you to define infrastructure using general-purpose programming languages like Python and TypeScript instead of a specialized language, offering better developer velocity and software testing practices.

- CloudFormation: An AWS-native IaC tool that is deeply integrated into the AWS ecosystem, which offers free resource management but is strictly limited to managing AWS services.


- Ansible: Primarily a configuration management and orchestration tool, whereas Terraform provisions the underlying servers and networks, making them highly complementary rather than direct competitors.

Task 2: Install Terraform (latest version)
==========================================
ubuntu@ip-172-31-35-252:~$ terraform version
terraform -help
Terraform v1.15.8
on linux_amd64
Usage: terraform [global options] <subcommand> [args]

The available commands for execution are listed below.
The primary workflow commands are given first, followed by
less common or more advanced commands.

Main commands:
  init          Prepare your working directory for other commands
  validate      Check whether the configuration is valid
  plan          Show changes required by the current configuration
  apply         Create or update infrastructure
  destroy       Destroy previously-created infrastructure

All other commands:
  console       Try Terraform expressions at an interactive command prompt
  fmt           Reformat your configuration in the standard style
  force-unlock  Release a stuck lock on the current workspace
  get           Install or upgrade remote Terraform modules
  graph         Generate a Graphviz graph of the steps in an operation
  import        Associate existing infrastructure with a Terraform resource
  login         Obtain and save credentials for a remote host
  logout        Remove locally-stored credentials for a remote host
  metadata      Metadata related commands
  modules       Show all declared modules in a working directory
  output        Show output values from your root module
  providers     Show the providers required for this configuration
  query         Search and list remote infrastructure with Terraform
  refresh       Update the state to match remote systems
  show          Show the current state or a saved plan
  stacks        Manage HCP Terraform stack operations
  state         Advanced state management
  taint         Mark a resource instance as not fully functional
  test          Execute integration tests for Terraform modules
  untaint       Remove the 'tainted' state from a resource instance
  version       Show the current Terraform version
  workspace     Workspace management

Global options (use these before the subcommand, if any):
  -chdir=DIR    Switch to a different working directory before executing the
                given subcommand.
  -help         Show this help output or the help for a specified subcommand.
  -version      An alias for the "version" subcommand.

Task 3: Learn 6 Crucial Terraform Terminologies
===================================================

Provider — a plugin that lets Terraform talk to a platform (AWS, Azure, Docker…).
-------------------------------------------------------------------------
-  A plugin that translates your HCL config into actual API calls against a specific platform without a provider, Terraform doesn't know how to talk to aws, gcp, azure, docker, github, etc...

provider "aws" {
  region = "us-west-2"
}


Resource — a piece of infrastructure you want to create (an EC2 instance, an S3 bucket…).
-------------------------------------------------------------------------------------
- The actual infrastructure object want terraform to create , update or destroy - a single unit of real stuff like a server, bucket or database.


State — Terraform's record of what it manages (the terraform.tfstate file).
---------------------------------------------------------------------
- Terraform's source of truth mapping - it tracks what it thinks exists in the real world (ids, attributes) so it can compute diffs on the next run. Lose this file (or corrupt it) and terraform loses track of what it owns.

terrafor.tfstate ->  { "aws_instance.web": { "id": "i-0abc123" } }


Plan — a preview of the changes Terraform will make.
----------------------------------------------------
- A dry run that compares  your .tf config against the current state and shows exactly what will changes before anything actually happens . This is your safety net.

terraform plan #shows "+ create", "~ update", "- destroy"



HCL — HashiCorp Configuration Language, the syntax you write Terraform in.
-----------------------------------------------------------------------
- HashiCorp configuration language - the declarative sysntax (blocks, arguments, expression) you write all your .tf files in. it's not a general - purpose language. it's built specifically to describe infrastructure.

variable "region" {
  default = "us-west-2"
}


Module — a reusable, packaged group of Terraform configuration.
---------------------------------------------------------------
- A folder of .tf files packaged as a reusable unit - you call it like a function , passing inputs and getting outputs, instead of copy- pasting the same VPC/EC2/SG code every where.


module "vpc" {
  source = "./modules/vpc"
  cidr = "10.0.0.0/16"
}



ubuntu@ip-172-31-35-252:~/TerraWeak$ ls
example
ubuntu@ip-172-31-35-252:~/TerraWeak$ vim main.tf
ubuntu@ip-172-31-35-252:~/TerraWeak$ cat main.tf
resource "random_pet" "name" {
        length    = 2
        separator = "-"
}

resource "local_file" "greeting" {
        filename        = "${path.module}/greeting.txt"
        content         = "Hello from Terraweek 2026! \n Your infra name is : ${random_pet.name.id}\n"
}

output "pet_name" {
        description = "The randomly generated pet name."
        value       = random_pet.name.id
}

output "file_path" {
        description = "Where the greeting file was written."
        value       = local_file.greeting.filename
}
ubuntu@ip-172-31-35-252:~/TerraWeak$ terraform init
Initializing the backend...

Initializing provider plugins...
- Finding latest version of hashicorp/random...
- Finding latest version of hashicorp/local...
- Installing hashicorp/local v2.9.0...
- Installed hashicorp/local v2.9.0 (signed by HashiCorp)
- Installing hashicorp/random v3.9.0...
- Installed hashicorp/random v3.9.0 (signed by HashiCorp)

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
ubuntu@ip-172-31-35-252:~/TerraWeak$ terraform fmt
main.tf
ubuntu@ip-172-31-35-252:~/TerraWeak$ terraform validate
Success! The configuration is valid.

ubuntu@ip-172-31-35-252:~/TerraWeak$ terraform plan

Terraform used the selected providers to generate the following execution plan. Resource
actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # local_file.greeting will be created
  + resource "local_file" "greeting" {
      + content              = (known after apply)
      + content_base64sha256 = (known after apply)
      + content_base64sha512 = (known after apply)
      + content_md5          = (known after apply)
      + content_sha1         = (known after apply)
      + content_sha256       = (known after apply)
      + content_sha512       = (known after apply)
      + directory_permission = "0777"
      + file_permission      = "0777"
      + filename             = "./greeting.txt"
      + id                   = (known after apply)
    }

  # random_pet.name will be created
  + resource "random_pet" "name" {
      + id        = (known after apply)
      + length    = 2
      + separator = "-"
    }

Plan: 2 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + file_path = "./greeting.txt"
  + pet_name  = (known after apply)

──────────────────────────────────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so Terraform can't guarantee to take
exactly these actions if you run "terraform apply" now.
ubuntu@ip-172-31-35-252:~/TerraWeak$ terraform apply

Terraform used the selected providers to generate the following execution plan. Resource
actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # local_file.greeting will be created
  + resource "local_file" "greeting" {
      + content              = (known after apply)
      + content_base64sha256 = (known after apply)
      + content_base64sha512 = (known after apply)
      + content_md5          = (known after apply)
      + content_sha1         = (known after apply)
      + content_sha256       = (known after apply)
      + content_sha512       = (known after apply)
      + directory_permission = "0777"
      + file_permission      = "0777"
      + filename             = "./greeting.txt"
      + id                   = (known after apply)
    }

  # random_pet.name will be created
  + resource "random_pet" "name" {
      + id        = (known after apply)
      + length    = 2
      + separator = "-"
    }

Plan: 2 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + file_path = "./greeting.txt"
  + pet_name  = (known after apply)

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

random_pet.name: Creating...
random_pet.name: Creation complete after 0s [id=notable-lizard]
local_file.greeting: Creating...
local_file.greeting: Creation complete after 0s [id=16038c226e9c558ea9815a51efa407bc08ebead4]

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:

file_path = "./greeting.txt"
pet_name = "notable-lizard"
ubuntu@ip-172-31-35-252:~/TerraWeak$ cat greeting.txt 
Hello from Terraweek 2026! 
 Your infra name is : notable-lizard
ubuntu@ip-172-31-35-252:~/TerraWeak$ terraform destroy
random_pet.name: Refreshing state... [id=notable-lizard]
local_file.greeting: Refreshing state... [id=16038c226e9c558ea9815a51efa407bc08ebead4]

Terraform used the selected providers to generate the following execution plan. Resource
actions are indicated with the following symbols:
  - destroy

Terraform will perform the following actions:

  # local_file.greeting will be destroyed
  - resource "local_file" "greeting" {
      - content              = <<-EOT
            Hello from Terraweek 2026! 
             Your infra name is : notable-lizard
        EOT -> null
      - content_base64sha256 = "3sNSQPycjovOzPMjxSBGtQOSlX0PEtmKp+Re8jvx8CU=" -> null
      - content_base64sha512 = "P4NFUANfRfcOmeQobyJcOgjDeYRcCvYgC2R5ahdwVKjxgBl32iKV8/0jjHg91lIE98FHX1HI63GNyNez9t9gWA==" -> null
      - content_md5          = "9e49d44b4e4a414e10b285c4c5fd64cc" -> null
      - content_sha1         = "16038c226e9c558ea9815a51efa407bc08ebead4" -> null
      - content_sha256       = "dec35240fc9c8e8bceccf323c52046b50392957d0f12d98aa7e45ef23bf1f025" -> null
      - content_sha512       = "3f834550035f45f70e99e4286f225c3a08c379845c0af6200b64796a177054a8f1801977da2295f3fd238c783dd65204f7c1475f51c8eb718dc8d7b3f6df6058" -> null
      - directory_permission = "0777" -> null
      - file_permission      = "0777" -> null
      - filename             = "./greeting.txt" -> null
      - id                   = "16038c226e9c558ea9815a51efa407bc08ebead4" -> null
    }

  # random_pet.name will be destroyed
  - resource "random_pet" "name" {
      - id        = "notable-lizard" -> null
      - length    = 2 -> null
      - separator = "-" -> null
    }

Plan: 0 to add, 0 to change, 2 to destroy.

Changes to Outputs:
  - file_path = "./greeting.txt" -> null
  - pet_name  = "notable-lizard" -> null

Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes

local_file.greeting: Destroying... [id=16038c226e9c558ea9815a51efa407bc08ebead4]
local_file.greeting: Destruction complete after 0s
random_pet.name: Destroying... [id=notable-lizard]
random_pet.name: Destruction complete after 0s

Destroy complete! Resources: 2 destroyed.
ubuntu@ip-172-31-35-252:~/TerraWeak$ ls
example  main.tf  terraform.tfstate  terraform.tfstate.backup
ubuntu@ip-172-31-35-252:~/TerraWeak$ vim terraform.tf
ubuntu@ip-172-31-35-252:~/TerraWeak$ terraform init
Initializing the backend...

Initializing provider plugins...
- Reusing previous version of hashicorp/local from the dependency lock file
- Reusing previous version of hashicorp/random from the dependency lock file
- Using previously-installed hashicorp/local v2.9.0
- Using previously-installed hashicorp/random v3.9.0


Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
ubuntu@ip-172-31-35-252:~/TerraWeak$ terraform fmt
terraform.tf
ubuntu@ip-172-31-35-252:~/TerraWeak$ terraform validate
Success! The configuration is valid.

ubuntu@ip-172-31-35-252:~/TerraWeak$ terraform plan

Terraform used the selected providers to generate the following execution plan. Resource
actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # local_file.greeting will be created
  + resource "local_file" "greeting" {
      + content              = (known after apply)
      + content_base64sha256 = (known after apply)
      + content_base64sha512 = (known after apply)
      + content_md5          = (known after apply)
      + content_sha1         = (known after apply)
      + content_sha256       = (known after apply)
      + content_sha512       = (known after apply)
      + directory_permission = "0777"
      + file_permission      = "0777"
      + filename             = "./greeting.txt"
      + id                   = (known after apply)
    }

  # random_pet.name will be created
  + resource "random_pet" "name" {
      + id        = (known after apply)
      + length    = 2
      + separator = "-"
    }

Plan: 2 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + file_path = "./greeting.txt"
  + pet_name  = (known after apply)

──────────────────────────────────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so Terraform can't guarantee to take
exactly these actions if you run "terraform apply" now.
ubuntu@ip-172-31-35-252:~/TerraWeak$ terraform apply

Terraform used the selected providers to generate the following execution plan. Resource
actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # local_file.greeting will be created
  + resource "local_file" "greeting" {
      + content              = (known after apply)
      + content_base64sha256 = (known after apply)
      + content_base64sha512 = (known after apply)
      + content_md5          = (known after apply)
      + content_sha1         = (known after apply)
      + content_sha256       = (known after apply)
      + content_sha512       = (known after apply)
      + directory_permission = "0777"
      + file_permission      = "0777"
      + filename             = "./greeting.txt"
      + id                   = (known after apply)
    }

  # random_pet.name will be created
  + resource "random_pet" "name" {
      + id        = (known after apply)
      + length    = 2
      + separator = "-"
    }

Plan: 2 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + file_path = "./greeting.txt"
  + pet_name  = (known after apply)

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

random_pet.name: Creating...
random_pet.name: Creation complete after 0s [id=hopeful-stingray]
local_file.greeting: Creating...
local_file.greeting: Creation complete after 0s [id=361fc4e664c724f5c0f7bb9c52ad6fd8997b149b]

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:

file_path = "./greeting.txt"
pet_name = "hopeful-stingray"
ubuntu@ip-172-31-35-252:~/TerraWeak$ ls
example  greeting.txt  main.tf  terraform.tf  terraform.tfstate  terraform.tfstate.backup
ubuntu@ip-172-31-35-252:~/TerraWeak$ cat terraform.tf
terraform {
  #Requires the modern terraform CLI. Latest stable at time of writting: 1.15.x
  required_version = ">= 1.10"

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
  }
}
ubuntu@ip-172-31-35-252:~/TerraWeak$ 


