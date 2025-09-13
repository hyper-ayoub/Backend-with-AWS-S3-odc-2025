# Terraform Import Lab - Complete Project Guide

## Project Overview

This lab demonstrates how to import an existing AWS EC2 instance into Terraform management. You'll learn how to bring existing infrastructure under Terraform control without recreating it.

## Prerequisites

- AWS CLI configured
- Terraform installed
- An existing EC2 instance in AWS (we'll use `i-002d81a53b54a5b42` as example)

## Step 1: Create Project Structure

```bash
mkdir terraform-import-lab && cd terraform-import-lab
```

## Step 2: Initial Configuration Files

### main.tf (Initial version)

```hcl
provider "aws" {
  region = "us-east-1"
}

# Placeholder resource for import
resource "aws_instance" "basma" {
  # Terraform just needs this block to exist.
  # The real values will be pulled from AWS after import.
}
```

## Step 3: Initialize Terraform

```bash
terraform init
```

This will:
- Download the AWS provider
- Create `.terraform/` directory
- Create `.terraform.lock.hcl` file

## Step 4: Import the Existing EC2 Instance

Run the import command:

```bash
terraform import aws_instance.basma i-002d81a53b54a5b42
```

Where:
- `aws_instance.basma` = Terraform resource name (you choose this)
- `i-002d81a53b54a5b42` = your actual EC2 instance ID

**Expected Output:**
```
aws_instance.basma: Importing from ID "i-002d81a53b54a5b42"...
aws_instance.basma: Import prepared!
aws_instance.basma: Refreshing state... [id=i-002d81a53b54a5b42]

Import successful!
```

## Step 5: Generate Configuration from State

After import, run:

```bash
terraform plan
```

You'll see Terraform wants to destroy the instance because the configuration doesn't match. Generate the current configuration:

```bash
terraform show -no-color > imported.tf
```

### Clean Up the Configuration

Create the final `main.tf` based on the imported configuration:

### main.tf (Final version)

```hcl
provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "basma" {
  ami           = "ami-0e95a5e2743ec9ec9"
  instance_type = "t2.micro"
  subnet_id     = "subnet-05513197850ae22bc"
  key_name      = "my-keypair"
  
  vpc_security_group_ids = [
    "sg-071e52c9d839a7111"
  ]
  
  root_block_device {
    volume_size = 8
    volume_type = "gp2"
  }
  
  tags = {
    Name = "basma-server"
  }
}
```

## Step 6: Verify Synchronization

```bash
terraform plan
```

**Expected Output:**
```
No changes. Infrastructure is up-to-date.

This means the import was successful!
```

## Step 7: Test Management

Now you can manage the instance with Terraform:

### Example: Change Instance Type

1. **Modify main.tf:**
```hcl
resource "aws_instance" "basma" {
  ami           = "ami-0e95a5e2743ec9ec9"
  instance_type = "t2.small"  # Changed from t2.micro
  subnet_id     = "subnet-05513197850ae22bc"
  key_name      = "my-keypair"
  
  vpc_security_group_ids = [
    "sg-071e52c9d839a7111"
  ]
  
  root_block_device {
    volume_size = 8
    volume_type = "gp2"
  }
  
  tags = {
    Name = "basma-server"
  }
}
```

2. **Plan the change:**
```bash
terraform plan
```

3. **Apply the change:**
```bash
terraform apply
```

## Additional Configuration Files

### variables.tf (Optional Enhancement)

```hcl
variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
  default     = "terraform-import-lab"
}
```

### outputs.tf (Optional Enhancement)

```hcl
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.basma.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.basma.public_ip
}

output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.basma.private_ip
}
```

## Project Structure (Final)

```
terraform-import-lab/
│── main.tf
│── variables.tf (optional)
│── outputs.tf (optional)
│── terraform.tfstate
│── terraform.tfstate.backup
│── .terraform.lock.hcl
│── imported.tf (temporary file)
└── .terraform/
    └── providers/
```
