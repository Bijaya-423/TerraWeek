
## Task 1: Workspaces & Environments

### What workspaces are
A Terraform **workspace** is a named slice of state within the same backend/config.
Each workspace gets its own `.tfstate` (e.g. `terraform.tfstate.d/staging/terraform.tfstate`
for local backends, or a workspace-scoped key in S3), so the *same* configuration can
manage multiple independent sets of real infrastructure (dev, staging, prod) without
duplicating `.tf` files.

```bash
terraform workspace list           # shows all workspaces, * marks current
terraform workspace new staging    # create + switch to it
terraform workspace select staging # switch to an existing one
terraform workspace show           # print current workspace name
```

### Using `terraform.workspace` in config

```hcl
locals {
  instance_type = terraform.workspace == "prod" ? "t3.medium" : "t3.micro"

  # common pattern: workspace-driven naming to avoid collisions
  name_prefix = "${terraform.workspace}-app"
}
```

### Trade-offs: workspaces vs. separate directories/backends

| | Workspaces | Separate directories/backends |
|---|---|---|
| **Code duplication** | None — one config, many state files | Config often copy-pasted or `-var-file`'d per env dir |
| **Blast radius** | Low isolation — one bad `apply` in the wrong workspace can hit the wrong env if you forget to `workspace select` first | High isolation — you can only apply what's physically in that directory |
| **Backend/provider differences per env** | Awkward — same backend config, same provider/region for every workspace | Easy — each directory can point at a totally different backend, account, or region |
| **State access control** | Hard to restrict per-environment IAM since it's one backend | Easy — separate S3 buckets/keys per env, separate IAM policies |
| **Good for** | Quick, low-stakes environment variants (e.g. personal dev sandboxes, ephemeral feature-branch environments) | Real prod/staging/dev separation where mistakes are expensive |

**Practical takeaway:** workspaces are great for lightweight, short-lived environment
variants. For prod-grade dev/staging/prod separation, most teams prefer separate
state backends (or at minimum separate S3 keys + strict IAM), because the isolation
is explicit rather than relying on remembering to `workspace select` correctly.

---

## Task 2: Quality Gates — `fmt`, `validate`, `test`

### Format and validate

```bash
terraform fmt -recursive   # rewrites files to canonical style, recursively
terraform validate         # checks internal consistency (types, required args, refs)
```

`fmt` only fixes *style* (indentation, alignment, quoting) — it doesn't catch logic
errors. `validate` checks that the configuration is internally consistent (e.g. a
referenced variable exists, argument types match), but it does **not** talk to your
cloud provider, so it won't catch a bad AMI ID or a resource that will fail on `apply`.

### Native `terraform test` (Terraform 1.6+)

```bash
cd example
terraform init
terraform test
```

Example test file (`example/tests/basic.tftest.hcl`):

```hcl
run "plan_creates_expected_instance_type" {
  command = plan

  variables {
    environment = "dev"
  }

  assert {
    condition     = module.web_server.instance_type == "t2.micro"
    error_message = "Dev environment should use t2.micro"
  }
}

run "apply_creates_reachable_instance" {
  command = apply

  assert {
    condition     = module.web_server.public_ip != ""
    error_message = "Instance should have a public IP after apply"
  }
}
```

### `plan`-based vs `apply`-based test commands

- **`command = plan`** — Terraform computes the plan but never creates real
  resources. Assertions run against planned values. Fast, free, safe to run on every
  commit/PR — but can't catch things that only fail at actual creation time (e.g. an
  AMI that doesn't exist in that region, an IAM permission gap, a name collision).
- **`command = apply`** — Terraform actually provisions real infrastructure for the
  duration of the test, asserts against the real resulting state/outputs, then tears
  it down automatically at the end of the test run. Slower and costs real money/time,
  but validates things a plan can't (actual resource creation succeeds, outputs are
  populated with real values, dependent resources actually come up correctly).

**Rule of thumb:** use `plan`-based tests liberally (cheap, run constantly in CI);
reserve `apply`-based tests for the handful of scenarios where you specifically need
to validate real provisioning behavior.

---

## Task 3: Security & Cost Scanning

Run a static analyzer against Day 3 or Day 5 code:

```bash
# Trivy (also subsumes tfsec's checks now)
trivy config .

# Checkov
checkov -d .

# tfsec (standalone, now part of Trivy)
tfsec .
```

Typical findings on beginner Terraform and how to fix them:

| Finding | Fix |
|---|---|
| Security group allows `0.0.0.0/0` ingress on a sensitive port | Scope `cidr_blocks` to known IP ranges, or front with a bastion/ALB |
| S3 bucket without encryption | Add `server_side_encryption_configuration` block |
| S3 bucket without versioning | Add `versioning { enabled = true }` |
| EBS volume not encrypted | Set `encrypted = true` on the `aws_instance`'s `root_block_device` or `aws_ebs_volume` |
| No `default_tags` / missing required tags | Add a `default_tags` block in the provider config |

**Bonus — cost estimation:**

```bash
infracost breakdown --path .
```
`infracost` reads your plan and prices out every resource against current cloud
pricing, so you can see the monthly cost impact of a PR *before* merging it —
useful for catching an accidentally-oversized instance type or an extra NAT gateway.

---

## Task 4: CI/CD with GitHub Actions

Copy the starter workflow to `.github/workflows/terraform.yml`:

```yaml
name: Terraform CI

on:
  pull_request:
    branches: [main]

jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3

      - name: Terraform Format Check
        run: terraform fmt -check -recursive

      - name: Terraform Init
        run: terraform init

      - name: Terraform Validate
        run: terraform validate

      - name: Terraform Plan
        run: terraform plan
```

**What each step does:**
- **`actions/checkout@v4`** — pulls the PR's branch into the runner so subsequent
  steps have the actual `.tf` files to work with.
- **`hashicorp/setup-terraform@v3`** — installs a pinned Terraform CLI version onto
  the runner (should specify `terraform_version:` explicitly rather than relying on
  "latest," for reproducibility).
- **`fmt -check -recursive`** — fails the build (non-zero exit) if any file isn't
  canonically formatted, *without* rewriting files — CI should never silently modify
  your code.
- **`init`** — downloads providers/modules and configures the backend.
- **`validate`** — catches internal config errors early, before wasting time on a
  `plan` against real cloud state.
- **`plan`** — shows exactly what would change; on a PR this becomes a reviewable
  artifact (often posted as a PR comment via an additional action) so reviewers see
  the infrastructure diff alongside the code diff.

Note this workflow deliberately stops at `plan` — it doesn't `apply` on every PR.
`apply` is typically gated behind a merge to `main` and/or manual approval, so
nothing touches real infrastructure just from opening a PR.

---

## Task 5: Best Practices Checklist

- ✅ **Remote state with locking** (Day 4) — S3 backend with native S3 locking
  (Terraform 1.10+) or DynamoDB lock table on older versions. `.tfstate` is in
  `.gitignore` and has never been committed — it can contain secrets in plaintext.
- ✅ **Pinned versions** — `required_version` for Terraform, `required_providers`
  with a version constraint, and every module `source` pinned (see Day 5, Task 5).
- ✅ **Reusable modules** (Day 5) — one `ec2_instance` module, called multiple times
  via `for_each`, consistent naming (`${terraform.workspace}-${var.name}`) and a
  shared `default_tags` block in the provider config so every resource is tagged
  the same way without repeating tags manually per resource.
- ✅ **No hard-coded secrets** — DB passwords, API keys, etc. come from `variable`s
  marked `sensitive = true`, populated via environment variables, `-var-file`s that
  are gitignored, or a secrets manager (AWS Secrets Manager / SSM Parameter Store) —
  never committed as literal strings in `.tf` files.
- ✅ **`fmt` + `validate` + `test` + security scan in CI** — all four run on every
  PR via the GitHub Actions workflow above, before any human reviews the plan.
- ✅ **Clear `README.md`** — includes an architecture diagram, prerequisites,
  how to `init`/`plan`/`apply`, required variables, and — critically — how to
  `terraform destroy` cleanly so nothing gets left running and billing.

---

## 🚫 Note on Provisioners

`remote-exec` / `local-exec` provisioners are a **last resort**, per HashiCorp's own
guidance:
- They break Terraform's declarative model — Terraform can plan/diff resource
  *attributes*, but it has no idea what a shell script actually did on the box, so it
  can't reason about drift the way it can for a resource argument.
- They require SSH connectivity (open ingress, key management) and are flaky on
  retries — if a `remote-exec` fails partway through, re-running `apply` can leave
  the instance in an inconsistent, hard-to-reproduce state.

**Prefer instead:**
- **`user_data`** / cloud-init — declarative, runs once at boot, no SSH needed.
- **Packer-baked images** — bake the configuration into the AMI itself, so the
  instance boots already-configured.
- **Config management (Ansible)** or **containers** — for anything more complex than
  boot-time setup, handle it with tooling built for that job rather than stretching
  Terraform to do configuration management.

---

## 🏗️ Capstone Project Notes

**Chosen architecture:** *(fill in — e.g. "2-tier web app: VPC + public/private
subnets + EC2 behind an ALB + S3 for static assets")*

**Requirements checklist:**

| Requirement | How it's met |
|---|---|
| 1. At least one custom module + one registry module | Custom: `modules/ec2_instance` (Day 5). Registry: `terraform-aws-modules/vpc/aws ~> 5.0` (Task 4, Day 5/6) |
| 2. Remote state, S3 native locking | `backend "s3"` block with `use_lockfile = true` (Terraform 1.10+), versioned + encrypted bucket |
| 3. Variables + outputs | All environment-specific values (`instance_type`, `cidr`, `environment`) are variables; public IPs / DNS names / ARNs exposed as outputs |
| 4. `fmt`, `validate`, security scan, `terraform test` | Enforced locally and in CI (Task 2–4 above) |
| 5. GitHub Actions wired up | `.github/workflows/terraform.yml` running on every PR |
| 6. `README.md` with architecture diagram | Diagram + run instructions included in repo root |
| 7. Clean `terraform destroy` | Verified: `terraform destroy` removes every resource with no orphaned dependencies |

> ⚠️ **Cost reminder:** if building on the EKS reference implementation, an EKS
> cluster + 2 NAT gateways runs **~$155/mo**. Spin it up only long enough to
> demo/screenshot, then `terraform destroy` immediately.
