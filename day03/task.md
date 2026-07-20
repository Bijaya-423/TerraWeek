
Task 1 — Version pinning & ~>
==============================

required_providers {
  aws = {
    source  = "hashicorp/aws"
    version = "~> 6.0"
  }
}

What ~> means (pessimistic constraint operator):

~> 6.0 → allows 6.0.x, 6.1.x, 6.9.x... but blocks 7.0.0. Only the rightmost version segment is allowed to increment.
~> 6.5.0 → allows only 6.5.x (patches), blocks 6.6.0.

So ~> 6.0 says: "give me any minor/patch update within the 6.x line, but never jump to a new major version that might break my resource blocks."

Task 2 — Resource vs Data Source
==================================
	resource	data
Action	Creates, updates, destroys	Only reads
Appears in terraform destroy?	Yes	No — nothing to tear down
Example here	aws_vpc.main (brand new VPC)	data.aws_ami.al2023 (looks up an existing AMI Amazon already publishes)

In main.tf, data "aws_ami" "al2023" never shows up as + create in a plan — it just resolves to an ID that aws_instance.critical then consumes as input. Same with data "aws_availability_zones" — it reads what AZs already exist in your region so the subnet can be placed correctly without you hardcoding "us-west-2a".




Task 3 — Running it
===================


bash
cd day3-example
terraform init
terraform validate
terraform plan
terraform apply      # type: yes
terraform state list

terraform state list should show every resource: aws_vpc.main, aws_subnet.public, aws_internet_gateway.igw, aws_route_table.public, aws_security_group.web_sg, plus the instances from Task 4.



Task 4 — Meta-arguments, side by side
=====================================



count (aws_instance.worker_pool) — indices [0], [1]... Fine for interchangeable workers, but risky: deleting the middle one shifts every later index and forces recreation of things you didn't mean to touch.

for_each (aws_instance.named) — keyed by map key ("web", "worker"). Removing "worker" from var.named_instances destroys only that instance; "web" is untouched. This is why for_each is preferred for anything with a real identity.

depends_on — used explicitly on aws_route_table.public even though the gateway_id reference already creates an implicit dependency. Use explicit depends_on when there's a dependency Terraform can't see from arguments alone (e.g. an IAM policy attachment that must exist before an app starts, with no direct attribute reference).

lifecycle — on aws_instance.critical:

create_before_destroy = true → spins up the replacement before killing the old one (avoids downtime on forced replacement)
prevent_destroy → flip to true and try terraform destroy — it'll refuse and error out, protecting genuinely critical infra from accidental deletion
ignore_changes = [tags["LastModified"]] → since timestamp() changes every single plan, this stops Terraform from perpetually wanting to "update" that one tag



Task 5 — Update & destroy
=========================

Try changing instance_type from "t3.micro" to "t3.small" in variables.tf, then:

bash
terraform plan

You'll see -/+ destroy and re-create (forces replace) — instance type changes require the EC2 instance to be replaced, not updated in place, because you can't resize a running instance's type via API the same way you can update a tag.

Compare that to changing just a tags value — that shows ~ update in-place, no replacement needed.

Always finish with:

bash
terraform destroy   # type: yes



