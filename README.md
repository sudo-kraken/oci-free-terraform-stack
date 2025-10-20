<div align="center">
<img src="docs/assets/logo.png" align="center" width="144px" height="144px"/>

### OCI Free Terraform Stack

_An opinionated Terraform module for Oracle Cloud Infrastructure that provisions a complete free-tier stack including compute and networking. Ships with a ready-to-run GitHub Actions workflow._
</div>

<div align="center">

[![Terraform](https://img.shields.io/badge/Terraform-Required-623CE4?logo=terraform&logoColor=white&style=for-the-badge)](https://www.terraform.io/)
[![Terraform Version](https://img.shields.io/badge/Terraform-1.6%2B-623CE4?logo=terraform&logoColor=white&style=for-the-badge)](https://www.terraform.io/)

</div>

<div align="center">

[![OpenSSF Scorecard](https://img.shields.io/ossf-scorecard/github.com/sudo-kraken/oci-free-terraform-stack?label=openssf%20scorecard&style=for-the-badge)](https://scorecard.dev/viewer/?uri=github.com/sudo-kraken/oci-free-terraform-stack)

</div>

## Contents

- [Overview](#overview)
- [Architecture at a glance](#architecture-at-a-glance)
- [Features](#features)
- [Prerequisites](#prerequisites)
  - [Secrets required](#secrets-required)
- [Automated deployment with GitHub Actions](#automated-deployment-with-github-actions)
  - [GitHub Action execution](#github-action-execution)
  - [Accessing the instances](#accessing-the-instances)
- [Quick start](#quick-start)
- [Troubleshooting](#troubleshooting)
- [Licence](#licence)
- [Security](#security)
- [Contributing](#contributing)
- [Support](#support)

## Overview

This module provisions an Oracle Cloud Infrastructure environment that fits the free-tier allowances. It creates compute, networking and storage so you can launch useful workloads at zero cost.

The stack includes:
- **2x VM.Standard.E2.1.Micro** instances, each with **1 OCPU** and **1 GB RAM**
- **1x VM.Standard.A1.Flex** instance with **4 OCPUs** and **24 GB RAM**, plus a **59 GB block volume**
- A **Virtual Cloud Network** with subnets, security lists and an internet gateway

> [!NOTE]  
> All resources are defined to align with free-tier constraints where applicable. Always check your tenancy and region limits.

## Architecture at a glance

- Terraform module defines:
  - VCN, subnets, security lists and internet gateway
  - Three compute instances as listed above
  - One block volume attached to the A1 Flex instance
- Opinionated security lists to enable typical access
- Ready-made GitHub Actions workflow to run Terraform from CI

## Features

- Free-tier friendly shapes and sizes
- Complete baseline networking with internet access
- Automated plan and apply from GitHub Actions
- Clean-up on failure to help maintain a tidy tenancy

## Prerequisites

- Oracle Cloud Infrastructure account
- Terraform 1.6 or newer
- **OCI API credentials** stored as GitHub Secrets

### Secrets required

| Secret name | Description |
|-------------|-------------|
| `PAT_TOKEN` | Personal Access Token used by the pipeline to check out the repository |
| `PKEY` | OCI SSH private key |
| `TENANCY_OCID` | OCID of your tenancy |
| `USER_OCID` | OCID of your user |
| `FP` | Fingerprint for the user’s API key |
| `SSH_PUB_KEY` | SSH public key added to the instances for access |

## Automated deployment with GitHub Actions

The workflow **Execute OCI Pipeline** performs the following:

- Checks out the repository to the GitHub runner
- Sets up **Node.js** and the **Terraform CLI** environments
- Configures the SSH private key and Terraform variables from **GitHub Secrets**
- Initialises Terraform, creates a plan and applies it
- On failure, automatically destroys provisioned resources to return to a clean state

### GitHub Action execution

The root **`main.tf`** is the entry point used by the workflow. It wires the module, variables and provisioners. As part of instance initialisation it **updates packages** and installs **Docker** and **Docker Compose**.

### Accessing the instances

When the workflow completes successfully, the **public IPs** of instances are shown in the Terraform outputs. Connect using:

- Username: `opc`  
- Authentication: the SSH key you provided in `SSH_PUB_KEY`

## Quick start

1. **Fork or clone** this repository into your GitHub account.
2. Create the **GitHub Secrets** listed above in your repository settings.
3. Review `main.tf` and the module variables to confirm regions, compartments and any tags.
4. Open the **Actions** tab, select **Execute OCI Pipeline**, provide any inputs and **run** it.
5. On completion, use the outputs to **SSH** to the instances as `opc`.

> [!NOTE]  
> If you prefer local execution, you can run `terraform init`, `terraform plan` and `terraform apply` from your workstation once your OCI credentials are exported appropriately. The CI workflow remains the recommended path.

## Troubleshooting

- **Apply failed or timed out**  
  Check the Actions logs for missing or incorrect secrets. Ensure the tenancy, compartment and region match your expectations.
- **Cannot SSH**  
  Verify that `SSH_PUB_KEY` matches your local private key and that security lists allow ingress from your IP.
- **Quota or service limits**  
  Free-tier entitlements and regional capacity can vary. Adjust regions or shapes if a resource cannot be created.

## Licence

This project is licensed under the MIT Licence. See the [LICENCE](LICENCE) file for details.

## Security

If you discover a security issue, please review and follow the guidance in [SECURITY.md](SECURITY.md), or open a private security-focused issue with minimal details and request a secure contact channel.

## Contributing

Feel free to open issues or submit pull requests if you have suggestions or improvements.  
See [CONTRIBUTING.md](CONTRIBUTING.md)

## Support

Open an [issue](/../../issues) with as much detail as possible, including your tenancy region, the workflow you ran and relevant Terraform logs.
