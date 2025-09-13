# Complete Terraform AWS Project

This project creates a complete AWS infrastructure including VPC, subnet, security group, and EC2 instance using Terraform best practices with a modular approach.

## Project Structure

```
terraform-aws-project/
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars
└── README.md
```

## Files

### main.tf

```hcl
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# ---------------------------
# NETWORK
# ---------------------------

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = var.vpc_name
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name = "${var.vpc_name}-igw"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true
  
  tags = {
    Name = var.public_subnet_name
    Tier = "public"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  
  tags = {
    Name = "${var.vpc_name}-public-rt"
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ---------------------------
# SECURITY
# ---------------------------

resource "aws_security_group" "web_ssh" {
  name        = "${var.vpc_name}-web-ssh"
  description = "Allow SSH, HTTP, HTTPS"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allow_ssh_cidr]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.vpc_name}-sg"
  }
}

# ---------------------------
# AMI (Amazon Linux 2)
# ---------------------------

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["137112412989"] # Amazon

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ---------------------------
# EC2
# ---------------------------

resource "aws_instance" "web" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.web_ssh.id]
  key_name                    = var.key_name
  associate_public_ip_address = true
  
  tags = {
    Name = var.instance_name
  }
  
  user_data = var.user_data # optional cloud-init/script
}
```

### variables.tf

```hcl
variable "region" {
  description = "AWS region"
  type        = string
}

variable "vpc_name" {
  description = "Name tag for the VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "public_subnet_name" {
  description = "Name tag for the public subnet"
  type        = string
}

variable "public_subnet_cidr" {
  description = "Public subnet CIDR"
  type        = string
}

variable "availability_zone" {
  description = "AZ for the public subnet"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "key_name" {
  description = "Existing EC2 key pair name"
  type        = string
}

variable "instance_name" {
  description = "EC2 Name tag"
  type        = string
}

variable "allow_ssh_cidr" {
  description = "CIDR allowed to SSH (use your IP/32)"
  type        = string
}

variable "user_data" {
  description = "Optional user_data script"
  type        = string
  default     = ""
}
```

### outputs.tf

```hcl
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.web.public_ip
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.web.id
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.web_ssh.id
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ~/.ssh/${var.key_name}.pem ec2-user@${aws_instance.web.public_ip}"
}
```

### terraform.tfvars

```hcl
# --- Global ---
region = "us-east-2"

# --- Network ---
vpc_name           = "my-vpc"
vpc_cidr           = "10.0.0.0/16"
public_subnet_name = "my-public-subnet"
public_subnet_cidr = "10.0.1.0/24"
availability_zone  = "us-east-2a"

# --- Compute ---
instance_type = "t2.micro"
key_name      = "my-keypair"  # Make sure this key pair exists in AWS
instance_name = "MyTerraformEC2"

# Restrict SSH to your public IP if possible (recommended)
allow_ssh_cidr = "0.0.0.0/0"  # Replace with "YOUR.IP.ADDR.ESS/32"

# Optional: Add user data script
# user_data = <<-EOF
#   #!/bin/bash
#   yum update -y
#   yum install -y httpd
#   systemctl start httpd
#   systemctl enable httpd
#   echo "<h1>Hello from Terraform!</h1>" > /var/www/html/index.html
# EOF
```

## How to Use

### Prerequisites

1. **AWS CLI configured** with appropriate credentials
2. **Terraform installed** (version >= 1.5.0)
3. **EC2 Key Pair** created in AWS (update `key_name` in terraform.tfvars)

### Deployment Steps

1. **Clone/Create the project structure:**
```bash
mkdir terraform-aws-project && cd terraform-aws-project
# Create all the files above
```

2. **Customize terraform.tfvars:**
```bash
# Edit terraform.tfvars with your specific values
# Especially: region, key_name, and allow_ssh_cidr
```

3. **Initialize Terraform:**
```bash
terraform init
```

4. **Plan the deployment:**
```bash
terraform plan
```

5. **Apply the configuration:**
```bash
terraform apply -auto-approve
```

6. **View outputs:**
```bash
terraform output
```

### Sample Output

After successful deployment, you'll see:
```
vpc_id = "vpc-xxxxxxxxxx"
public_subnet_id = "subnet-xxxxxxxxxx"
instance_public_ip = "x.x.x.x"
instance_id = "i-xxxxxxxxxx"
security_group_id = "sg-xxxxxxxxxx"
ssh_command = "ssh -i ~/.ssh/my-keypair.pem ec2-user@x.x.x.x"
```

### Security Considerations

1. **SSH Access**: Replace `0.0.0.0/0` with your specific IP address (`YOUR_IP/32`)
2. **Key Pair**: Ensure your EC2 key pair exists before deployment
3. **Region**: Verify the availability zone exists in your chosen region

### Cleanup

To destroy all resources:
```bash
terraform destroy -auto-approve
```

## What Gets Created

This Terraform configuration creates:

- **VPC** with DNS support and hostnames enabled
- **Internet Gateway** for internet access
- **Public Subnet** in specified availability zone
- **Route Table** with internet access route
- **Security Group** allowing SSH (port 22), HTTP (port 80), and HTTPS (port 443)
- **EC2 Instance** (Amazon Linux 2) in the public subnet with public IP

## Customization Options

- **Instance Size**: Modify `instance_type` in terraform.tfvars
- **User Data**: Uncomment and customize the user_data section for automatic software installation
- **Multiple Subnets**: Extend the configuration to create private subnets
- **Load Balancer**: Add application load balancer for web applications
- **RDS Database**: Add database subnet group and RDS instance

This project provides a solid foundation for AWS infrastructure that can be extended based on your specific requirements.
