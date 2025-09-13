# Terraform Modules Guide

## Modular Structure

This architecture uses two main modules:
- **network** → to create VPC, subnets, route tables, etc.
- **server** → to create EC2 instances that will use the network.

## Project Directory Structure

```
our-project/
│── main.tf
│── variables.tf
│── terraform.tfvars
│
├── modules/
│   ├── network/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   └── server/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
```

## Network Module

### modules/network/main.tf

```hcl
resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "${var.project}-vpc"
  }
}

resource "aws_subnet" "public" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = element(var.azs, count.index)
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.project}-public-${count.index + 1}"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.project}-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.project}-rt-public"
  }
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}
```

### modules/network/variables.tf

```hcl
variable "project" {}
variable "vpc_cidr" {}
variable "public_subnets" { type = list(string) }
variable "azs" { type = list(string) }
```

### modules/network/outputs.tf

```hcl
output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}
```

## Server Module

### modules/server/main.tf

```hcl
resource "aws_instance" "this" {
  ami           = var.ami
  instance_type = var.instance_type
  subnet_id     = element(var.subnet_ids, 0)
  key_name      = var.key_name
  tags = {
    Name = "${var.project}-server"
  }
}
```

### modules/server/variables.tf

```hcl
variable "project" {}
variable "ami" {}
variable "instance_type" {}
variable "subnet_ids" { type = list(string) }
variable "key_name" {}
```

### modules/server/outputs.tf

```hcl
output "instance_id" {
  value = aws_instance.this.id
}

output "public_ip" {
  value = aws_instance.this.public_ip
}
```

## Root Files

### main.tf

```hcl
provider "aws" {
  region = var.region
}

module "network" {
  source          = "./modules/network"
  project         = var.project
  vpc_cidr        = var.vpc_cidr
  public_subnets  = var.public_subnets
  azs             = var.azs
}

module "server" {
  source        = "./modules/server"
  project       = var.project
  ami           = var.ami
  instance_type = var.instance_type
  subnet_ids    = module.network.public_subnet_ids
  key_name      = var.key_name
}
```

### variables.tf

```hcl
variable "project" {}
variable "region" {}
variable "vpc_cidr" {}
variable "public_subnets" { type = list(string) }
variable "azs" { type = list(string) }
variable "ami" {}
variable "instance_type" {}
variable "key_name" {}
```

### terraform.tfvars

```hcl
project         = "our-project"
region          = "eu-west-1"
vpc_cidr        = "10.0.0.0/16"
public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
azs             = ["eu-west-1a", "eu-west-1b"]
ami             = "ami-0c55b159cbfafe1f0"
instance_type   = "t2.micro"
key_name        = "my-key"
```

## Benefits of This Structure

- ✅ **Separation of concerns**: The network module handles all networking resources
- ✅ **Reusability**: The server module deploys EC2 instances based on the created network  
- ✅ **Modularity**: You can easily reuse modules in other projects
- ✅ **Maintainability**: Organized and easy-to-maintain code
- ✅ **Scalability**: Easy to add new modules (database, load balancer, etc.)
