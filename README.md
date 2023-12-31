# Scalable and Secure Web Application Architecture

This repository contains Terraform scripts to set up an AWS environment with an auto-scaling EC2 setup behind a load balancer and an RDS instance.

## Architecture

The Terraform scripts create the following resources in AWS:

- Load Balancer: Distributes incoming traffic across EC2 instances.
- Auto Scaling Group: Automatically scales the number of EC2 instances based on demand.
- EC2 Instances: Hosting the web application.
- RDS Instance: Relational database to store application data.

## Prerequisites

- AWS CLI installed and configured with proper credentials. ([AWS CLI Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html))
- Terraform CLI installed. ([Terraform Installation Guide](https://learn.hashicorp.com/tutorials/terraform/install-cli))

## Instructions

1. Clone this repository:

   ```bash
   git clone https://github.com/your-username/web-application.git
   cd web-application
