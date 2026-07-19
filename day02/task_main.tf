Task 1: Master HCL Syntax
=========================

block_type "label_one" "label_two" {
  argument = value
}


block_type - resource - Tells terraform what kind of declaration this is

"label_one" - "aws_instance" - First label - usually the type (Which provider resource)

"lable_two" - "web" - Second label - a name you choose, for referencing later

{} - Body of the block, holds arguments

argument = value - instance_type = "t3.micro" - Actual configuration setting

Task 2: Variables, Types & Validation
======================================
db_password -> sensitive values (password and api keys , token) should never be hardcoded with a default in version conteolled .tf files . instead you did supply it at run via

terraform apply -var="db_password=your-secret-here"
- or better, an untracked secrets.auto.tfvars (add to .gitignore), or a secrets manager.

sensitive = true -> actually does- it does not encrypt the value - it just tells terraform to dedact it from cli output (plan/apply) logs will show (sensitive value) instead of the real password
. THe value is still stored in plain text inside terraform.tfstate, so state file encryption/access-control is still your responsivility separately.

object vs tuple , quick distiction

terraform init
terraform validate
terraform plan -var="db_password=test123"

########################################
# Task 2: Variables, Types & Validation
########################################

##############
# PRIMITIVES #
##############

# string
variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

# number
variable "instance_count" {
  description = "Number of EC2 instances to launch"
  type        = number
  default     = 1

  validation {
    condition     = var.instance_count > 0 && var.instance_count <= 5
    error_message = "instance_count must be between 1 and 5."
  }
}

# bool
variable "enable_monitoring" {
  description = "Whether to enable detailed CloudWatch monitoring"
  type        = bool
  default     = false
}


###############
# COLLECTIONS #
###############

# list(string) - ordered, can contain duplicates
variable "availability_zones" {
  description = "List of availability zones to deploy into"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b"]
}

# map(string) - key-value pairs, keys must be unique
variable "resource_tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default = {
    Project = "terra-auto"
    Owner   = "seere"
    Env     = "dev"
  }
}

# set(string) - unordered, unique values only
variable "allowed_ports" {
  description = "Set of inbound ports allowed through the security group"
  type        = set(string)
  default     = ["22", "80", "443"]
}


################
# STRUCTURAL   #
################

# object({...}) - fixed set of named attributes, each with its own type
variable "instance_config" {
  description = "Structured configuration for the EC2 instance"
  type = object({
    instance_type = string
    volume_size   = number
    monitoring    = bool
  })
  default = {
    instance_type = "t3.micro"
    volume_size   = 20
    monitoring    = false
  }
}

# tuple([...]) - fixed-length, ordered, each position can have a different type
variable "instance_metadata" {
  description = "Tuple of [name, port, is_public] for a single instance"
  type        = tuple([string, number, bool])
  default     = ["terra-auto-server", 22, true]
}


######################################
# SENSITIVE VARIABLE (no default set # 
# intentionally - should be passed   #
# via terraform.tfvars or env var,   #
# never committed to source control) #
######################################

variable "db_password" {
  description = "Password for the database master user"
  type        = string
  sensitive   = true
}


Task 3: Locals, Outputs & Functions
===================================
locals
========

locals {
  # format() - build a consistent naming prefix from environment + project
  name_prefix = format("%s-%s", "terra-auto", var.environment)

  # upper() - normalize environment name for a tag value
  environment_upper = upper(var.environment)

  # merge() - combine the default resource_tags map with extra computed tags,
  # without mutating the original variable
  common_tags = merge(
    var.resource_tags,
    {
      Name        = local.name_prefix
      Environment = local.environment_upper
      ManagedBy   = "terraform"
    }
  )

  # join() - turn the allowed_ports set into a single comma-separated string,
  # useful for logging/display purposes since sets can't be printed directly
  allowed_ports_display = join(", ", var.allowed_ports)

  # length() - count how many AZs were provided, used below to decide
  # whether we're in a multi-AZ setup
  az_count = length(var.availability_zones)

  # lookup() - safely pull a key out of a map with a fallback default,
  # avoids an error if the key doesn't exist
  owner_tag = lookup(var.resource_tags, "Owner", "unassigned")
}

# Outputs
==========
output "name_prefix" {
  description = "Computed naming prefix used across resources"
  value       = local.name_prefix
}

output "common_tags" {
  description = "Merged tag map applied to resources (base tags + computed tags)"
  value       = local.common_tags
}

output "allowed_ports_display" {
  description = "Human-readable comma-separated list of allowed inbound ports"
  value       = local.allowed_ports_display
}

output "availability_zone_count" {
  description = "Number of availability zones configured"
  value       = local.az_count
}

output "resource_owner" {
  description = "Owner tag, defaulting to 'unassigned' if not set"
  value       = local.owner_tag
}

# Marked sensitive so `terraform apply`/`output` don't print the raw value
output "db_password_length" {
  description = "Length of the db password (avoids exposing the actual value)"
  value       = length(var.db_password)
  sensitive   = true
}


6 built in functions used (task asked for 3+): format(), upper(), merge(), join(), lenght(), lookup()

what each does, briefly
-----------------------

format("%s-%s", a, b) → sprintf-style string building → "terra-auto-dev"

upper(str) → uppercases a string → "DEV"

merge(map1, map2) → combines maps, later keys override earlier ones on conflict

join(sep, list) → turns a list/set into one string → "22, 80, 443"

length(collection) → counts items in a list/set/map, or characters in a string

lookup(map, key, default) → safely reads a map value, returns default if the key's missing (avoids a hard error)

> upper("terraweek")
"TERRAWEEK"

> merge({a=1}, {b=2})
{
  "a" = 1
  "b" = 2
}

> join("-", ["tws", "terraweek", "2026"])
"tws-terraweek-2026"

> lookup({Owner="seere", Env="dev"}, "Owner", "unknown")
"seere"

> length(["us-west-2a", "us-west-2b"])
2

> format("%s-%s", "terra-auto", "dev")
"terra-auto-dev"

Task 4: Build Something Real (Docker provider — no cloud cost)
==============================================================
# terraform.tf

terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}

# example/variables.tf
variable "container_name" {
  type    = string
  default = "nginx"
}

variable "external_port" {
  type    = number
  default = 80
}

variable "image" {
  type    = string
  default = "nginx:latest"
}

# example/main.tf
resource "docker_image" "nginx" {
  name = var.image
}

resource "docker_container" "web" {
  name  = var.container_name
  image = docker_image.nginx.image_id

  ports {
    internal = 80
    external = var.external_port
  }
}

# example/outputs.tf
output "container_id" {
  value = docker_container.web.id
}

output "url" {
  value = "http://localhost:${var.external_port}"
}




runnning
---------
cd example
terraform init

Downloads the kreuzwerker/docker provider plugin (different from hashicorp/aws — same terraform init mechanism, different provider entirely).

terraform plan  -var 'container_name=tws-web' -var 'external_port=8080'
terraform apply -var 'container_name=tws-web' -var 'external_port=8080'

terraform output

terraform destroy -var 'container_name=tws-web' -var 'external_port=8080'

terraform plan
terraform apply
terraform destroy
