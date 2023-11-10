# Terraform OCI Stack Module (Free Forever)
This module is used for provisioning Oracle Cloud Infrastructure (OCI) deployments, offering a comprehensive and efficient solution for setting up a robust cloud environment. It seamlessly provisions a stack comprising of;
  - 2x VM.Standard.E2.1.Micro instances, each with 1 OCPU and 1 GB RAM
  - 1x VM.Standard.A1.Flex instance equipped with 4 OCPUs and 24 GB RAM. Additionally, it includes a 59 GB block volume

A pivotal aspect of this module is its sophisticated networking setup, creating a Virtual Cloud Network (VCN) with all necessary components, such as subnets, security lists, and internet gateways, ensuring seamless connectivity and security. 

## Prerequisites
 - Oracle Cloud Infrastructure account
 - OCI API Credentials stored in the form of GitHub Secrets

### Secrets Required
| Secret Name | Description |
|-------------|-------------|
| `GH_TOKEN` | PAT Token the pipeline uses to checkout the repo. |
| `PKEY` | OCI SSH private key. |
| `TENANCY_OCID` | OCID of your OCI tenancy. |
| `USER_OCID` | OCID of the OCI user. |
| `FP` | Fingerprint for the OCI user. |
| `SSH_PUB_KEY` | SSH public key you wish to use for accessing the provisioned instances. |

## Automated Deployment with GitHub Actions
This module is designed for seamless integration with GitHub Actions, allowing for automated deployment. The provided GitHub Action workflow, named 'Execute OCI Pipeline', is triggered manually and performs the following tasks:

- Checks out the repository to the GitHub Actions runner.
- Sets up Node.js and Terraform CLI environments.
- Configures SSH Private Key and Terraform variables using GitHub Secrets.
- Initialises Terraform and generates an execution plan.
- Applies the Terraform configuration to deploy the resources.
- In case of failure, the workflow is designed to automatically destroy the resources, ensuring a clean state.

## GitHub Action Execution
The `main.tf` file located in the root directory of this repository is crucial for the GitHub Action execution. It serves as the entry point for the Terraform operations triggered by the GitHub Action workflow. When the workflow is run, it uses the configuration defined in `main.tf` to deploy the module. This configuration includes updating and installing additional packages, including Docker and Docker Compose, on the instances.

### Accessing the Instances
Upon successful completion of the action, the public IPs of the instances will be displayed in the output. You can access these instances via SSH using the username `opc` and the SSH key you have provided. The SSH key is crucial for secure and authenticated access to the instances.

It's important to ensure that `main.tf` is correctly set up and updated, as it directly influences the infrastructure that the GitHub Action will provision and manage in OCI (Oracle Cloud Infrastructure).

