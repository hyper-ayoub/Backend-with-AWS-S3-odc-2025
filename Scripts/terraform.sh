#!/bin/bash

# Update packages
sudo apt update

# Install dependencies
sudo apt install -y wget unzip

# Download Terraform (single line URL)
wget https://releases.hashicorp.com/terraform/1.8.5/terraform_1.8.5_linux_amd64.zip

# Unzip
unzip terraform_1.8.5_linux_amd64.zip

# Move binary to PATH
sudo mv terraform /usr/local/bin/

# Verify installation
terraform -version