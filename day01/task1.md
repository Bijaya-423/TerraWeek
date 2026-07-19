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
