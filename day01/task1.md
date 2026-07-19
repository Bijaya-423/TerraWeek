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
