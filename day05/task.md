# Day 5 — Terraform Modules

## Task 1: Modules — the Why

### What is a module? What counts as the root module?

A **module** is just a directory containing `.tf` files. Every Terraform configuration
has at least one module — the **root module** — which is the directory you run
`terraform init` / `plan` / `apply` from (in this repo, that's `./example` or `./day5`).

Any module that gets called via a `module "name" { source = ... }` block is a
**child module**. Child modules can live locally (`./modules/ec2_instance`), in a Git
repo, or in the Terraform Registry. Modules can also call other modules, forming a
tree — but the root module is always the entry point Terraform starts evaluating from.

In short:
- **Root module** = the directory you execute Terraform commands in.
- **Child/reusable module** = any directory referenced by a `module` block, meant to
  be called (possibly many times, from many places) rather than executed directly.

### Benefits of using modules

- **Reusability** — write the `aws_instance` + tagging + networking logic once in
  `modules/ec2_instance`, then call it for `web`, `app`, `worker`, `cache`, etc.
  without copy-pasting resource blocks.
- **Consistency** — every instance created through the module gets the same tagging
  scheme, naming convention, and resource arguments. No risk of one instance quietly
  drifting from another because someone forgot a tag.
- **Encapsulation** — the module hides its internal resource names/implementation.
  Callers only interact with **inputs** (`variables.tf`) and **outputs** (`outputs.tf`),
  so the internals can change (e.g. swap `aws_instance` for a launch template) without
  breaking anything that calls the module, as long as the interface stays the same.
- **Versioning** — registry/Git modules can be pinned to a specific version or commit,
  so upgrades are deliberate and reviewed, not accidental (see Task 5).
- **Testing** — a small, single-purpose module is far easier to reason about, plan,
  and validate in isolation than one giant root module with everything inlined.
  Terraform test tooling (`terraform test`, Terratest, etc.) also works best against
  modules with a clean, well-defined input/output contract.

### Files that make up a well-structured module

| File | Purpose |
|---|---|
| `main.tf` | The actual resources the module manages. |
| `variables.tf` | Input variables — the module's public "parameters." Should include `description` and `type` for every variable, and sensible `default`s where appropriate. |
| `outputs.tf` | Values the module exposes back to whatever calls it (IDs, IPs, ARNs, etc.). |
| `README.md` | Human documentation: what the module does, example usage, inputs/outputs table, requirements (Terraform/provider versions). Not required by Terraform itself, but essential for anyone (including future-you) reusing the module. |

Optional but common additions: `versions.tf` (provider/Terraform version constraints
scoped to the module), `locals.tf`, and `examples/` directories showing real usage.

---

## Task 2: Write Your Own Module

Studied `./example`, which contains:
- Reusable module: `./example/modules/ec2_instance`
- Root module: `./example` — resolves the AMI, default VPC, subnet, and security
  group **once** via `data` sources, stores them in `locals`, and passes them into
  the module as inputs.

```hcl
module "web_server" {
  source                 = "./modules/ec2_instance"
  name                   = "web"
  instance_type          = "t2.micro"
  environment            = "dev"
  ami                    = data.aws_ami.al2023.id   # resolved in the root
  subnet_id              = local.subnet_id
  vpc_security_group_ids = local.security_group_ids
}

output "web_public_ip" {
  value = module.web_server.public_ip
}
```

**Key takeaway:** the module takes IDs as *inputs* rather than doing its own
`data` lookups internally. If every instantiation of the module ran its own
`data "aws_ami"` lookup, that's the same lookup repeated N times for N instances —
wasteful, and it opens the door to inconsistency if the "latest" AMI changes between
one module call and the next in the same apply. Resolving once in the root and
passing the result down keeps every instance consistent and the module reusable
in contexts where the caller might want a different AMI entirely.

Commands run:

```bash
cd example
terraform init      # Terraform discovers and initializes the local module
terraform plan
terraform apply
terraform destroy
```

`terraform init` output confirms the module was picked up with a line like
`Initializing modules... - web_server in modules/ec2_instance`.

---

## Task 3: Modular Composition (`for_each`)

Added to the root module, calling the **same** module multiple times to build
several servers without duplicating resource blocks:

```hcl
module "servers" {
  source   = "./modules/ec2_instance"
  for_each = toset(["app", "worker", "cache"])

  name                   = each.key
  instance_type          = "t2.micro"
  environment            = "dev"
  ami                    = data.aws_ami.al2023.id
  subnet_id              = local.subnet_id
  vpc_security_group_ids = local.security_group_ids
}

output "server_ips" {
  description = "Private IPs of every for_each server, keyed by name."
  value       = { for k, m in module.servers : k => m.private_ip }
}
```

**Observations from `terraform plan`:**
- Each key in the `for_each` set (`"app"`, `"worker"`, `"cache"`) produces its own
  module instance, addressed as `module.servers["app"]`, `module.servers["worker"]`,
  `module.servers["cache"]`.
- Because it's `for_each` (map/set-keyed) rather than `count` (index-keyed), instances
  are stable by name — removing `"worker"` from the set only destroys that one
  instance, instead of shifting indices and potentially destroying/recreating
  unrelated instances the way `count` can.
- Reading outputs across all instances uses a `for` expression over
  `module.servers`, producing a map of `name => private_ip`.

---

## Task 4: Consume a Registry Module + Version Locking

Using the official, widely-used AWS VPC module from the Terraform Registry:

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"   # ✅ always pin registry/git module versions

  name = "terraweek-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Project = "terraweek-2026"
  }
}
```

After adding this, `terraform init` downloads the module source into
`.terraform/modules/` and records the resolved version in `.terraform.lock.hcl`
(for providers) — the module version itself is tracked via the `version` constraint
in the config, which is why pinning it matters (see Task 5).

---

## Task 5: Ways to Lock Module Versions

### 1. Registry module — version constraint

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"   # allows 5.x, blocks 6.0
}
```

Other valid constraint styles:

```hcl
version = "= 5.1.2"          # exact version only
version = ">= 5.0, < 6.0"    # explicit range
version = "~> 5.1.2"         # allows 5.1.3, 5.1.4... but not 5.2.0
```

### 2. Git source, pinned to a tag/ref

```hcl
module "ec2_instance" {
  source = "git::https://github.com/org/repo.git//modules/ec2_instance?ref=v1.2.0"
}
```

The `?ref=` query parameter can point to a branch, tag, or commit. Using a **tag**
(`v1.2.0`) is the Git equivalent of a semantic version pin.

### 3. Git source, pinned to a commit SHA (fully immutable)

```hcl
module "ec2_instance" {
  source = "git::https://github.com/org/repo.git//modules/ec2_instance?ref=8f14e45fceea167a5a36dedd4bea2543ea55dcbb"
}
```

A tag can technically be force-moved to point at a different commit later (rare, but
possible). A commit SHA cannot — it always resolves to the exact same code. This is
the strongest guarantee of immutability for a Git-sourced module.

### Why pinning matters

- **Reproducible builds** — anyone (or any CI pipeline) running `terraform init` on
  this config today or a year from now gets the *exact same* module code, not
  whatever the module's maintainers happen to have pushed most recently.
- **No surprise breaking changes** — module authors can and do introduce breaking
  changes even within what looks like a minor bump. An unpinned `source` (or an
  overly loose constraint) means your next `terraform init` / `plan` could silently
  pull in different resource arguments, renamed outputs, or new required variables —
  discovered only when `plan` breaks or, worse, when `apply` changes infrastructure
  you didn't intend to touch.
- **Auditable upgrades** — with a pin in place, upgrading a module version is a
  deliberate, reviewable change (bump the `version`/`ref`, re-run `plan`, review the
  diff) rather than something that happens to you automatically.
